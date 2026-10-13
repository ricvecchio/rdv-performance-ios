// Serviço de autorização administrativa para cadastro de professores.
// Implementação com Firebase Authentication + Cloud Firestore (compatível com o plano Spark).
// A proteção efetiva é feita pelas regras do Firestore (ver firebase/firestore-teacher-authorization.rules):
//  - somente o administrador lê/gera o código;
//  - o código só é verificável por quem já o conhece (leitura por ID, listagem bloqueada);
//  - um perfil TRAINER só pode ser criado junto com o registro de um código vigente;
//  - cada código autoriza um único cadastro concluído (teacher_signup_code_uses/{código}, imutável).
import Foundation
import Security
import FirebaseAuth
import FirebaseFirestore

// Erros amigáveis do fluxo de autorização de professores
enum TeacherAuthorizationError: LocalizedError, Equatable {
    case invalidCode
    case tooManyAttempts
    case authorizationRequired
    case authorizationExpired
    // Código já consumido por um cadastro de professor concluído (uso único)
    case codeAlreadyUsed
    case notConfigured
    case permissionDenied
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case invalidData
    case network
    // Resposta inesperada do servidor (não é falha de conexão)
    case backendError
    case unknown

    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    var errorDescription: String? {
        let locale = Self.localizationLocale
        switch self {
        case .invalidCode:
            return AppLocalization.string("teacher_authorization.error.invalid_code", locale: locale)
        case .tooManyAttempts:
            return AppLocalization.string("teacher_authorization.error.too_many_attempts", locale: locale)
        case .authorizationRequired:
            return AppLocalization.string("teacher_authorization.error.authorization_required", locale: locale)
        case .authorizationExpired:
            return AppLocalization.string("teacher_authorization.error.authorization_expired", locale: locale)
        case .codeAlreadyUsed:
            return AppLocalization.string("teacher_authorization.error.code_already_used", locale: locale)
        case .notConfigured:
            return AppLocalization.string("teacher_authorization.error.not_configured", locale: locale)
        case .permissionDenied:
            return AppLocalization.string("teacher_authorization.error.permission_denied", locale: locale)
        case .emailAlreadyInUse:
            return AppLocalization.string("teacher_authorization.error.email_in_use", locale: locale)
        case .invalidEmail:
            return AppLocalization.string("teacher_authorization.error.invalid_email", locale: locale)
        case .weakPassword:
            return AppLocalization.string("teacher_authorization.error.weak_password", locale: locale)
        case .invalidData:
            return AppLocalization.string("teacher_authorization.error.invalid_data", locale: locale)
        case .network:
            return AppLocalization.string("teacher_authorization.error.network", locale: locale)
        case .backendError, .unknown:
            return AppLocalization.string("teacher_authorization.error.unknown", locale: locale)
        }
    }
}

// Código de autorização vigente (exibido somente ao administrador)
struct TeacherAuthorizationCode: Equatable {
    let code: String
    let version: Int
}

// Guarda em memória (nunca persistida) a autorização validada no servidor durante o fluxo de cadastro.
// O valor não concede acesso por si só: as regras do Firestore revalidam o código no momento
// da criação do perfil TRAINER, e um código substituído pelo administrador deixa de funcionar.
@MainActor
final class TeacherSignupAuthorizationStore {
    static let shared = TeacherSignupAuthorizationStore()

    private(set) var ticket: String?

    private init() {}

    func store(ticket: String) {
        self.ticket = ticket
    }

    func clear() {
        ticket = nil
    }
}

// Cliente do mecanismo de autorização (Firestore + Firebase Auth)
final class TeacherAuthorizationService {

    // Coleções utilizadas (devem coincidir com as regras do Firestore)
    private enum Path {
        static let config = "teacher_signup_config"
        static let configDocument = "current"
        static let codes = "teacher_signup_codes"
        static let redemptions = "teacher_signup_redemptions"
        // Consumo definitivo e permanente: um documento por código (ID = código), criado uma única vez
        static let codeUses = "teacher_signup_code_uses"
        static let users = "users"
    }

    // Erros de consumo sinalizados de dentro da transação de cadastro
    private static let consumptionErrorDomain = "TeacherAuthorization.consumption"
    private static let consumptionAlreadyUsed = 1
    private static let consumptionExpired = 2

    // Alfabeto sem caracteres ambíguos (sem I, O, 0 e 1): 32 símbolos => 5 bits por caractere
    private static let codeAlphabet: [Character] = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    private static let codeAlphabetSet: Set<Character> = Set(codeAlphabet)
    private static let inputCharacters: Set<Character> = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    private static let codePrefix = "RDV"
    private static let codeGroupLength = 4
    private static let codeLength = 12 // 12 caracteres aleatórios (60 bits)

    private var db: Firestore { Firestore.firestore() }

    init() {}

    // Valida o código informado contra o Firestore e retorna a autorização (código normalizado),
    // mantida apenas em memória até a conclusão do cadastro
    func validateCode(_ code: String) async throws -> String {
        guard let normalized = Self.normalize(code) else {
            throw TeacherAuthorizationError.invalidCode
        }

        let exists: Bool
        do {
            exists = try await codeExists(normalized)
        } catch {
            // Sem permissão de leitura = regras ainda não publicadas
            throw mapFirestoreError(error, operation: "validate", permissionDenied: .notConfigured)
        }

        guard exists else {
            throw TeacherAuthorizationError.invalidCode
        }

        // Código vigente, mas já consumido por um cadastro concluído
        let used: Bool
        do {
            used = try await codeUseExists(normalized)
        } catch {
            throw mapFirestoreError(error, operation: "validate", permissionDenied: .notConfigured)
        }
        guard !used else {
            throw TeacherAuthorizationError.codeAlreadyUsed
        }
        return normalized
    }

    // Cria a conta de professor: Firebase Auth + perfil TRAINER no Firestore.
    // A criação do perfil é aceita pelas regras somente se o código ainda estiver vigente
    // e ainda não tiver sido consumido (teacher_signup_code_uses/{código} criado uma única vez).
    func createTeacherAccount(ticket: String, form: RegisterFormDTO) async throws -> String {
        guard let code = Self.normalize(ticket) else {
            throw TeacherAuthorizationError.authorizationExpired
        }

        // 1) Revalida no servidor antes de criar a conta no Auth (evita contas sem perfil)
        let stillValid: Bool
        var alreadyUsed = false
        do {
            stillValid = try await codeExists(code)
            if stillValid {
                alreadyUsed = try await codeUseExists(code)
            }
        } catch {
            throw mapFirestoreError(error, operation: "precheck", permissionDenied: .notConfigured)
        }
        guard stillValid else {
            throw TeacherAuthorizationError.authorizationExpired
        }
        guard !alreadyUsed else {
            throw TeacherAuthorizationError.codeAlreadyUsed
        }

        // 2) Cria a conta no Firebase Authentication
        let user: User
        do {
            user = try await Auth.auth().createUser(withEmail: form.email, password: form.password).user
        } catch {
            throw mapAuthError(error)
        }

        // 3) Grava, em uma única transação, o consumo definitivo do código, o registro de uso
        //    (auditoria por UID) e o perfil TRAINER. A transação relê o consumo no servidor:
        //    se outro cadastro consumir o código antes, a confirmação falha (pré-condição) e,
        //    na nova tentativa, o código é recusado. As regras impõem a mesma unicidade.
        let uid = user.uid
        let db = self.db
        let codeRef = db.collection(Path.codes).document(code)
        let codeUseRef = db.collection(Path.codeUses).document(code)
        let redemptionRef = db.collection(Path.redemptions).document(uid)
        let userRef = db.collection(Path.users).document(uid)

        let profile: [String: Any] = [
            "name": form.name,
            "email": form.email,
            "userType": UserTypeDTO.TRAINER.rawValue,
            "phone": Self.optionalValue(form.phone),
            "focusArea": form.focusArea ?? FocusAreaDTO.CROSSFIT.rawValue,
            "cref": Self.optionalValue(form.cref),
            "bio": Self.optionalValue(form.bio),
            "gymName": Self.optionalValue(form.gymName),
            "defaultCategory": NSNull(),
            "active": NSNull(),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                do {
                    let useSnapshot = try transaction.getDocument(codeUseRef)
                    if useSnapshot.exists {
                        errorPointer?.pointee = NSError(
                            domain: Self.consumptionErrorDomain,
                            code: Self.consumptionAlreadyUsed
                        )
                        return nil
                    }

                    let codeSnapshot = try transaction.getDocument(codeRef)
                    guard codeSnapshot.exists else {
                        errorPointer?.pointee = NSError(
                            domain: Self.consumptionErrorDomain,
                            code: Self.consumptionExpired
                        )
                        return nil
                    }

                    transaction.setData(
                        ["usedAt": FieldValue.serverTimestamp()],
                        forDocument: codeUseRef
                    )

                    transaction.setData(
                        [
                            "code": code,
                            "createdAt": FieldValue.serverTimestamp()
                        ],
                        forDocument: redemptionRef
                    )

                    transaction.setData(profile, forDocument: userRef)
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch {
            let mapped = await mapProfileCreationError(error, code: code)
            await rollback(user)
            throw mapped
        }

        // 4) Encerra a sessão criada pelo Auth; o chamador autentica novamente para que a
        //    sessão do app carregue o perfil já gravado (mesmo comportamento anterior).
        try? Auth.auth().signOut()
        return uid
    }

    // Consulta o código vigente (somente administrador, verificado pelas regras do Firestore).
    // No primeiro acesso, gera o código inicial.
    func fetchCurrentCode() async throws -> TeacherAuthorizationCode {
        try await runAdminTransaction(rotate: false)
    }

    // Gera um novo código e invalida o anterior (somente administrador, verificado pelas regras)
    func rotateCode() async throws -> TeacherAuthorizationCode {
        try await runAdminTransaction(rotate: true)
    }

    // MARK: - Administração

    private func runAdminTransaction(rotate: Bool) async throws -> TeacherAuthorizationCode {
        guard let adminUid = Auth.auth().currentUser?.uid else {
            throw TeacherAuthorizationError.permissionDenied
        }

        let db = self.db
        let configRef = db.collection(Path.config).document(Path.configDocument)
        let codes = db.collection(Path.codes)
        let codeUses = db.collection(Path.codeUses)
        let operation = rotate ? "rotate" : "fetch"

        let result: Any?
        do {
            result = try await db.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(configRef)
                    let data = snapshot.data() ?? [:]
                    let currentVersion = (data["version"] as? NSNumber)?.intValue ?? 0
                    let currentDisplay = data["code"] as? String
                    let currentCodeId = (data["codeId"] as? String).flatMap { Self.isValidRawCode($0) ? $0 : nil }

                    // Consulta: retorna o código vigente se estiver íntegro (documento do código existente)
                    // e ainda não consumido. Código já utilizado nunca é reapresentado como disponível:
                    // um novo código é gerado (o histórico de consumo é preservado).
                    if !rotate, let currentCodeId, let currentDisplay, !currentDisplay.isEmpty {
                        let codeSnapshot = try transaction.getDocument(codes.document(currentCodeId))
                        let useSnapshot = try transaction.getDocument(codeUses.document(currentCodeId))
                        if codeSnapshot.exists && !useSnapshot.exists {
                            let current: [String: Any] = ["code": currentDisplay, "version": currentVersion]
                            return current
                        }
                    }

                    // Geração (primeiro acesso, substituição, código consumido ou estado inconsistente).
                    // Nunca reutiliza um código já emitido ou consumido: em colisão, gera outro.
                    var generatedCode: String?
                    for _ in 0..<5 {
                        guard let candidate = Self.generateRawCode() else { break }
                        let existing = try transaction.getDocument(codes.document(candidate))
                        let consumed = try transaction.getDocument(codeUses.document(candidate))
                        if !existing.exists && !consumed.exists {
                            generatedCode = candidate
                            break
                        }
                    }
                    guard let rawCode = generatedCode else {
                        errorPointer?.pointee = NSError(domain: "TeacherAuthorization", code: -1)
                        return nil
                    }

                    let newVersion = snapshot.exists ? currentVersion + 1 : 1
                    let display = Self.format(rawCode)

                    transaction.setData(
                        [
                            "version": newVersion,
                            "createdAt": FieldValue.serverTimestamp()
                        ],
                        forDocument: codes.document(rawCode)
                    )

                    // Invalida o código anterior na mesma transação
                    if let currentCodeId, currentCodeId != rawCode {
                        transaction.deleteDocument(codes.document(currentCodeId))
                    }

                    transaction.setData(
                        [
                            "code": display,
                            "codeId": rawCode,
                            "version": newVersion,
                            "updatedAt": FieldValue.serverTimestamp(),
                            "updatedBy": adminUid
                        ],
                        forDocument: configRef
                    )

                    let generated: [String: Any] = ["code": display, "version": newVersion]
                    return generated
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
        } catch {
            throw mapFirestoreError(error, operation: operation, permissionDenied: .permissionDenied)
        }

        guard
            let dict = result as? [String: Any],
            let code = dict["code"] as? String,
            !code.isEmpty
        else {
            logDiagnostic(operation, "transaction without result")
            throw TeacherAuthorizationError.backendError
        }

        let version = dict["version"] as? Int ?? 0
        return TeacherAuthorizationCode(code: code, version: version)
    }

    // MARK: - Código

    // Geração criptograficamente segura (SecRandomCopyBytes). 256 é múltiplo de 32: sem viés.
    private static func generateRawCode() -> String? {
        var bytes = [UInt8](repeating: 0, count: codeLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { return nil }
        return String(bytes.map { codeAlphabet[Int($0) & 31] })
    }

    private static func format(_ raw: String) -> String {
        var groups: [String] = []
        var current = raw.startIndex
        while current < raw.endIndex {
            let next = raw.index(current, offsetBy: codeGroupLength, limitedBy: raw.endIndex) ?? raw.endIndex
            groups.append(String(raw[current..<next]))
            current = next
        }
        return ([codePrefix] + groups).joined(separator: "-")
    }

    // Normaliza a entrada: ignora hífens/espaços, aceita com ou sem o prefixo "RDV"
    private static func normalize(_ input: String) -> String? {
        guard input.count <= 64 else { return nil }
        var value = String(input.uppercased().filter { inputCharacters.contains($0) })
        if value.count == codePrefix.count + codeLength, value.hasPrefix(codePrefix) {
            value.removeFirst(codePrefix.count)
        }
        return isValidRawCode(value) ? value : nil
    }

    private static func isValidRawCode(_ value: String) -> Bool {
        value.count == codeLength && value.allSatisfy { codeAlphabetSet.contains($0) }
    }

    private static func optionalValue(_ value: String?) -> Any {
        guard let value, !value.isEmpty else { return NSNull() }
        return value
    }

    // Leitura sempre no servidor (nunca do cache local)
    private func codeExists(_ code: String) async throws -> Bool {
        let snapshot = try await db.collection(Path.codes).document(code).getDocument(source: .server)
        return snapshot.exists
    }

    // Consumo definitivo do código (leitura sempre no servidor)
    private func codeUseExists(_ code: String) async throws -> Bool {
        let snapshot = try await db.collection(Path.codeUses).document(code).getDocument(source: .server)
        return snapshot.exists
    }

    // MARK: - Erros e consistência

    // Desfaz a conta criada no Auth quando o perfil não pôde ser gravado
    private func rollback(_ user: User) async {
        do {
            try await user.delete()
        } catch {
            logDiagnostic("create", "unable to roll back auth account")
        }
        try? Auth.auth().signOut()
    }

    private func mapProfileCreationError(_ error: Error, code: String) async -> TeacherAuthorizationError {
        let ns = error as NSError

        // Recusa determinada pela própria transação (leitura no servidor)
        if ns.domain == Self.consumptionErrorDomain {
            if ns.code == Self.consumptionAlreadyUsed {
                logDiagnostic("create", "code already consumed")
                return .codeAlreadyUsed
            }
            logDiagnostic("create", "code no longer active")
            return .authorizationExpired
        }

        guard
            ns.domain == FirestoreErrorDomain,
            ns.code == FirestoreErrorCode.permissionDenied.rawValue
        else {
            return mapFirestoreError(error, operation: "create", permissionDenied: .notConfigured)
        }

        // Negado pelas regras: diferencia código consumido, código substituído e regras não publicadas
        if let used = try? await codeUseExists(code), used {
            logDiagnostic("create", "permission denied: code already consumed")
            return .codeAlreadyUsed
        }
        if let exists = try? await codeExists(code), !exists {
            logDiagnostic("create", "permission denied: code no longer active")
            return .authorizationExpired
        }
        logDiagnostic("create", "permission denied: firestore rules not published or not merged")
        return .notConfigured
    }

    private func mapFirestoreError(
        _ error: Error,
        operation: String,
        permissionDenied: TeacherAuthorizationError
    ) -> TeacherAuthorizationError {
        if let authorizationError = error as? TeacherAuthorizationError {
            return authorizationError
        }

        let ns = error as NSError
        guard ns.domain == FirestoreErrorDomain else {
            logDiagnostic(operation, "error domain=\(ns.domain) code=\(ns.code)")
            return .backendError
        }

        let mapped: TeacherAuthorizationError
        switch ns.code {
        case FirestoreErrorCode.permissionDenied.rawValue,
             FirestoreErrorCode.unauthenticated.rawValue:
            mapped = permissionDenied
        case FirestoreErrorCode.unavailable.rawValue,
             FirestoreErrorCode.deadlineExceeded.rawValue:
            mapped = .network
        case FirestoreErrorCode.resourceExhausted.rawValue:
            mapped = .tooManyAttempts
        default:
            mapped = .backendError
        }
        logDiagnostic(operation, "firestore code=\(ns.code) mapped=\(mapped)")
        return mapped
    }

    private func mapAuthError(_ error: Error) -> TeacherAuthorizationError {
        let ns = error as NSError
        guard ns.domain == AuthErrorDomain else { return .unknown }

        switch ns.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue: return .emailAlreadyInUse
        case AuthErrorCode.invalidEmail.rawValue: return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue: return .weakPassword
        case AuthErrorCode.networkError.rawValue: return .network
        case AuthErrorCode.tooManyRequests.rawValue: return .tooManyAttempts
        default:
            logDiagnostic("create", "auth code=\(ns.code)")
            return .unknown
        }
    }

    // Log apenas de diagnóstico (DEBUG): nunca inclui código, senha, token ou dados pessoais
    private func logDiagnostic(_ operation: String, _ message: String) {
        #if DEBUG
        print("[TeacherAuthorization] \(operation): \(message)")
        #endif
    }
}


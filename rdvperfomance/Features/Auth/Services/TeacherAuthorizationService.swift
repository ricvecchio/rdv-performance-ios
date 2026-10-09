// Serviço de autorização administrativa para cadastro de professores (Cloud Functions)
import Foundation
import FirebaseAuth
import FirebaseCore

// Erros amigáveis do fluxo de autorização de professores
enum TeacherAuthorizationError: LocalizedError, Equatable {
    case invalidCode
    case tooManyAttempts
    case authorizationRequired
    case authorizationExpired
    case notConfigured
    case permissionDenied
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case invalidData
    case network
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
        case .functionUnavailable:
            // Reutiliza a mensagem existente: o serviço ainda não está disponível no servidor
            return AppLocalization.string("teacher_authorization.error.not_configured", locale: locale)
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

// Guarda em memória (nunca persistida) a autorização temporária emitida pelo backend.
// A proteção efetiva é feita no servidor: o ticket é de uso único, expira e é invalidado
// quando o administrador gera um novo código.
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

// Cliente das funções "callable" do Firebase via HTTPS (sem dependências adicionais)
final class TeacherAuthorizationService {

    // Deve coincidir com a região configurada em functions/index.js
    private let region = "us-central1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Valida o código informado e retorna uma autorização temporária de uso único
    func validateCode(_ code: String) async throws -> String {
        let result = try await call(
            "validateTeacherSignupCode",
            payload: ["code": code],
            requiresAuthentication: false
        )

        guard let ticket = result["ticket"] as? String, !ticket.isEmpty else {
            throw TeacherAuthorizationError.unknown
        }
        return ticket
    }

    // Cria a conta de professor no backend, consumindo a autorização temporária
    func createTeacherAccount(ticket: String, form: RegisterFormDTO) async throws -> String {
        let payload: [String: Any] = [
            "ticket": ticket,
            "name": form.name,
            "email": form.email,
            "password": form.password,
            "phone": form.phone ?? "",
            "focusArea": form.focusArea ?? FocusAreaDTO.CROSSFIT.rawValue,
            "cref": form.cref ?? "",
            "bio": form.bio ?? "",
            "gymName": form.gymName ?? ""
        ]

        let result = try await call(
            "createTeacherAccount",
            payload: payload,
            requiresAuthentication: false
        )

        guard let uid = result["uid"] as? String, !uid.isEmpty else {
            throw TeacherAuthorizationError.unknown
        }
        return uid
    }

    // Consulta o código vigente (somente administrador, verificado no servidor)
    func fetchCurrentCode() async throws -> TeacherAuthorizationCode {
        let result = try await call(
            "getTeacherSignupCode",
            payload: [:],
            requiresAuthentication: true
        )
        return try parseCode(result)
    }

    // Gera um novo código e invalida o anterior (somente administrador, verificado no servidor)
    func rotateCode() async throws -> TeacherAuthorizationCode {
        let result = try await call(
            "rotateTeacherSignupCode",
            payload: [:],
            requiresAuthentication: true
        )
        return try parseCode(result)
    }

    // MARK: - Private

    private func parseCode(_ result: [String: Any]) throws -> TeacherAuthorizationCode {
        guard let code = result["code"] as? String, !code.isEmpty else {
            throw TeacherAuthorizationError.unknown
        }
        let version = (result["version"] as? NSNumber)?.intValue ?? 0
        return TeacherAuthorizationCode(code: code, version: version)
    }

    private func endpoint(for functionName: String) throws -> URL {
        guard
            let projectID = FirebaseApp.app()?.options.projectID,
            !projectID.isEmpty,
            let url = URL(string: "https://\(region)-\(projectID).cloudfunctions.net/\(functionName)")
        else {
            throw TeacherAuthorizationError.notConfigured
        }
        return url
    }

    private func call(
        _ functionName: String,
        payload: [String: Any],
        requiresAuthentication: Bool
    ) async throws -> [String: Any] {

        var request = URLRequest(url: try endpoint(for: functionName))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuthentication {
            guard let user = Auth.auth().currentUser else {
                throw TeacherAuthorizationError.permissionDenied
            }
            let token: String
            do {
                token = try await user.getIDToken()
            } catch {
                throw TeacherAuthorizationError.network
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: ["data": payload])
        } catch {
            throw TeacherAuthorizationError.invalidData
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            // Falha real de transporte (sem resposta do servidor)
            logDiagnostic(functionName, "transport error: \((error as? URLError)?.code.rawValue ?? -1)")
            throw TeacherAuthorizationError.network
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]

        // Erro estruturado do protocolo callable: {"error": {"status": ..., "details": {"reason": ...}}}
        if let errorObject = json["error"] as? [String: Any] {
            let mapped = mapError(errorObject)
            logDiagnostic(
                functionName,
                "HTTP \(statusCode) status=\(errorObject["status"] as? String ?? "-") mapped=\(mapped)"
            )
            throw mapped
        }

        guard (200..<300).contains(statusCode) else {
            // Resposta sem objeto de erro callable (ex.: página HTML do Google).
            // Não é falha de conexão: o servidor respondeu.
            let mapped: TeacherAuthorizationError = statusCode == 404 ? .functionUnavailable : .backendError
            logDiagnostic(functionName, "HTTP \(statusCode) without callable error body, mapped=\(mapped)")
            throw mapped
        }

        guard let result = json["result"] as? [String: Any] else {
            logDiagnostic(functionName, "HTTP \(statusCode) without result object")
            throw TeacherAuthorizationError.backendError
        }
        return result
    }

    // Log apenas de diagnóstico (DEBUG): nunca inclui código, ticket, senha, token ou dados pessoais
    private func logDiagnostic(_ functionName: String, _ message: String) {
        #if DEBUG
        print("[TeacherAuthorization] \(functionName): \(message)")
        #endif
    }

    private func mapError(_ errorObject: [String: Any]) -> TeacherAuthorizationError {
        let details = errorObject["details"] as? [String: Any]
        let reason = details?["reason"] as? String ?? ""

        switch reason {
        case "invalid-code": return .invalidCode
        case "too-many-attempts": return .tooManyAttempts
        case "authorization-expired": return .authorizationExpired
        case "not-configured": return .notConfigured
        case "permission-denied": return .permissionDenied
        case "email-already-exists": return .emailAlreadyInUse
        case "invalid-email": return .invalidEmail
        case "weak-password": return .weakPassword
        case "invalid-data": return .invalidData
        default: break
        }

        switch (errorObject["status"] as? String ?? "").uppercased() {
        case "INVALID_ARGUMENT": return .invalidData
        case "RESOURCE_EXHAUSTED": return .tooManyAttempts
        case "FAILED_PRECONDITION": return .authorizationExpired
        case "PERMISSION_DENIED", "UNAUTHENTICATED": return .permissionDenied
        case "ALREADY_EXISTS": return .emailAlreadyInUse
        case "UNAVAILABLE", "DEADLINE_EXCEEDED": return .network
        case "NOT_FOUND": return .functionUnavailable
        case "INTERNAL", "UNKNOWN": return .backendError
        default: return .unknown
        }
    }
}


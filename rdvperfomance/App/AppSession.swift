import Foundation
import SwiftUI
import UIKit
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AdminProfileMode: Equatable {
    case administrator
    case student
    case trainer
}

/// Gerencia o estado de autenticação e perfil do usuário no app
@MainActor
final class AppSession: ObservableObject {

    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""
    @AppStorage("preferredWeightUnit") private var preferredWeightUnit: String = "kg"

    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil
    @Published private(set) var isAdmin: Bool = false
    @Published private(set) var adminProfileMode: AdminProfileMode? = nil
    @Published private(set) var measurementUnitLoadState: MeasurementUnitLoadState = .idle
    /// Conta marcada como inativa (`users/{uid}.active == false`) na última tentativa de acesso
    @Published private(set) var isAccountDisabled: Bool = false
    /// Restauração inicial em andamento: verdadeiro até a primeira resposta do Firebase Auth
    /// (e, havendo usuário, até a resolução do perfil usado na navegação). Nunca volta a ser verdadeiro.
    @Published private(set) var isRestoringSession: Bool = true


    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    // Custom claim emitida somente pelo Firebase Admin SDK (ambiente confiável)
    private let administratorClaim = "admin"
    // Evita gravações repetidas da mesma versão instalada (somente em memória)
    private var reportedAppVersionKey: String?
    // Evita gravações repetidas do último acesso/aparelho na mesma sessão (somente em memória)
    private var reportedAccessUid: String?
    // Intervalo mínimo entre registros de último acesso quando o aparelho não mudou
    private let lastAccessMinimumInterval: TimeInterval = 15 * 60

    enum MeasurementUnitLoadState {
        case idle
        case loading
        case loaded
        case missing
        case failed
    }

    /// Inicializa a sessão e restaura estado persistido ou limpa em modo DEBUG
    init() {
        PersonalRecordsSyncService.shared.prepareForAppLaunch()

        #if DEBUG
        self.storedUid = ""
        self.storedUserTypeRaw = ""
        self.storedUserName = ""

        self.uid = nil
        self.userType = nil
        self.userName = nil

        do {
            try Auth.auth().signOut()
        } catch {
        }
        #else
        self.uid = storedUid.isEmpty ? nil : storedUid
        self.userType = storedUserTypeRaw.isEmpty ? nil : UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName
        #endif

        observeAuthState()
    }

    /// Remove o listener de autenticação ao destruir o objeto
    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // Retorna verdadeiro se existe um usuário autenticado
    // Perfil ADMIN só é aceito após validação no servidor (perfil + custom claim)
    var isLoggedIn: Bool {
        guard uid != nil, !isAccountDisabled else { return false }
        if isAdmin { return true }
        guard let userType else { return false }
        return userType != .ADMIN
    }

    // Retorna o identificador único do usuário autenticado
    var currentUid: String? { uid }

    // Retorna o tipo de usuário em formato string
    var currentUserTypeRaw: String? { userType?.rawValue }

    // Retorna verdadeiro se o usuário é um aluno
    var isStudent: Bool {
        if isAdmin { return adminProfileMode == .student }
        return userType?.rawValue.lowercased() == "student"
    }

    // Retorna verdadeiro se o usuário é um professor
    var isTrainer: Bool {
        if isAdmin { return adminProfileMode == .trainer }
        return userType?.rawValue.lowercased() == "trainer"
    }

    func selectAdminProfile(_ mode: AdminProfileMode) {
        guard isAdmin else { return }
        adminProfileMode = mode
    }

    func clearAdminProfileMode() {
        guard isAdmin else { return }
        adminProfileMode = nil
    }

    // Observa mudanças no estado de autenticação do Firebase
    private func observeAuthState() {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                if let user {
                    PersonalRecordsSyncService.shared.prepareForAuthenticatedUser(uid: user.uid)
                    self.preferredWeightUnit = "kg"
                    self.measurementUnitLoadState = .loading
                    self.uid = user.uid
                    self.isAdmin = false
                    self.isAccountDisabled = false
                    self.adminProfileMode = nil
                    self.storedUid = user.uid
                    await self.loadUserProfile(uid: user.uid)
                    // Perfil resolvido (sucesso, inexistente, inativo ou falha): a navegação já pode decidir.
                    // A sincronização de recordes não bloqueia a abertura.
                    self.isRestoringSession = false
                    await PersonalRecordsSyncService.shared.synchronizeForAuthenticatedUser(uid: user.uid)
                } else {
                    PersonalRecordsSyncService.shared.handleLogout()
                    self.clearSession()
                    self.isRestoringSession = false
                }
            }
        }
    }

    // Recarrega o perfil do usuário atual do Firestore
    func refreshProfile() async {
        guard let uid else { return }
        await loadUserProfile(uid: uid)
    }

    // Carrega nome e tipo de usuário do documento Firestore
    func loadUserProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument(source: .server)

            guard let data = snap.data() else {
                #if DEBUG
                print("[AppSession] Perfil inexistente: users/\(uid) não existe no banco (default).")
                #endif
                self.userType = nil
                self.userName = nil
                self.isAdmin = false
                self.adminProfileMode = nil
                self.measurementUnitLoadState = .failed

                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                return
            }

            let name = data["name"] as? String
            let typeRaw = data["userType"] as? String

            // Conta inativa: não concede acesso. `nil`/ausente (registros legados) = ativa.
            // O bloqueio efetivo dos dados é feito pelas regras do Firestore.
            if (data["active"] as? Bool) == false {
                #if DEBUG
                print("[AppSession] users/\(uid) está inativa (active == false). Sessão encerrada.")
                #endif
                self.isAccountDisabled = true
                self.userType = nil
                self.userName = nil
                self.isAdmin = false
                self.adminProfileMode = nil
                self.measurementUnitLoadState = .failed
                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                try? Auth.auth().signOut()
                return
            }
            self.isAccountDisabled = false

            let remotePhotoBase64 = (data["photoBase64"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let remoteMeasurementUnit = (data["measurementUnit"] as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if LocalProfileStore.shared.getPhotoBase64(userId: uid) != remotePhotoBase64 {
                LocalProfileStore.shared.setPhotoBase64(remotePhotoBase64, userId: uid)
            }

            self.userName = name
            self.userType = typeRaw.flatMap { UserTypeDTO(rawValue: $0) }

            // Administrador: perfil ADMIN (lido do servidor) + custom claim "admin" no token do Firebase Auth.
            // A alternância de modo (AdminProfileMode) é preservada enquanto o usuário continuar administrador.
            var validatedAdmin = false
            if self.userType == .ADMIN {
                validatedAdmin = await self.hasAdministratorClaim(uid: uid)
            }
            self.isAdmin = validatedAdmin
            if !validatedAdmin {
                self.adminProfileMode = nil
            }

            #if DEBUG
            if typeRaw != nil && self.userType == nil {
                print("[AppSession] users/\(uid) possui userType não reconhecido.")
            }
            if self.userType == .ADMIN && !validatedAdmin {
                print("[AppSession] users/\(uid) possui userType ADMIN, mas o token não contém a custom claim admin=true. Acesso administrativo negado.")
            }
            #endif

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

            self.reportInstalledAppVersionIfNeeded(uid: uid, profileData: data)
            self.reportLastAccessAndDeviceIfNeeded(uid: uid, profileData: data)

            switch remoteMeasurementUnit {
            case "kg", "lbs":
                self.preferredWeightUnit = remoteMeasurementUnit
                self.measurementUnitLoadState = .loaded
            case "":
                self.measurementUnitLoadState = .missing
            default:
                self.measurementUnitLoadState = .failed
                #if DEBUG
                print("[Settings] Unidade de medida remota inválida.")
                #endif
            }

        } catch {
            self.measurementUnitLoadState = .failed
            #if DEBUG
            let ns = error as NSError
            print("[AppSession] Falha ao ler users/\(uid) (não é perfil inexistente): domain=\(ns.domain) code=\(ns.code) — \(ns.localizedDescription)")
            #endif
        }
    }

    // Desconecta o usuário do Firebase e limpa a sessão
    func logout() {
        PersonalRecordsSyncService.shared.handleLogout()
        do {
            try Auth.auth().signOut()
            clearSession()
        } catch {
            clearSession()
        }
    }

    // Limpa todos os dados da sessão local e persistida
    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil
        isAdmin = false
        adminProfileMode = nil
        measurementUnitLoadState = .idle

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
        reportedAccessUid = nil
    }

    // Registra a versão instalada no perfil do próprio usuário somente quando ela muda.
    // Não bloqueia a sessão: falhas são ignoradas (nova tentativa no próximo carregamento do perfil).
    private func reportInstalledAppVersionIfNeeded(uid: String, profileData data: [String: Any]) {
        guard let version = AppVersionService.installedVersionString() else { return }
        let build = AppVersionService.installedBuildString()

        let storedVersion = data["appVersion"] as? String
        let storedBuild = data["appBuild"] as? String
        guard storedVersion != version || storedBuild != build else { return }

        let key = "\(uid)|\(version)|\(build ?? "")"
        guard reportedAppVersionKey != key else { return }
        reportedAppVersionKey = key

        Task { @MainActor [weak self] in
            do {
                try await FirestoreRepository.shared.setInstalledAppVersion(uid: uid, version: version, build: build)
            } catch {
                if self?.reportedAppVersionKey == key {
                    self?.reportedAppVersionKey = nil
                }
                #if DEBUG
                print("[AppSession] Não foi possível registrar a versão instalada: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // Registra o último acesso (timestamp do servidor) e o aparelho do próprio usuário, no máximo uma vez
    // por sessão e somente se o aparelho mudou ou o último registro tem mais de `lastAccessMinimumInterval`.
    // Não bloqueia a sessão: falhas são ignoradas (nova tentativa no próximo carregamento do perfil).
    private func reportLastAccessAndDeviceIfNeeded(uid: String, profileData data: [String: Any]) {
        guard reportedAccessUid != uid else { return }

        let device = UserDeviceInfo.current()
        let deviceChanged = (data["deviceModel"] as? String) != device.model
            || (data["deviceSystem"] as? String) != device.system
            || (data["deviceIdentifier"] as? String) != device.identifier
        let lastAccess = (data["lastAccessAt"] as? Timestamp)?.dateValue()
        let recentlyRecorded = lastAccess.map { abs($0.timeIntervalSinceNow) < lastAccessMinimumInterval } ?? false
        guard deviceChanged || !recentlyRecorded else { return }

        reportedAccessUid = uid

        Task { @MainActor [weak self] in
            do {
                try await FirestoreRepository.shared.setLastAccessAndDevice(
                    uid: uid,
                    model: device.model,
                    system: device.system,
                    identifier: device.identifier
                )
            } catch {
                if self?.reportedAccessUid == uid {
                    self?.reportedAccessUid = nil
                }
                #if DEBUG
                print("[AppSession] Não foi possível registrar o último acesso: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // Verifica a custom claim administrativa no token emitido pelo Firebase Auth.
    // A renovação forçada garante que concessões/revogações recentes sejam refletidas
    // (inclusive no token usado pelo Firestore para avaliar as regras).
    private func hasAdministratorClaim(uid: String) async -> Bool {
        guard let user = Auth.auth().currentUser, user.uid == uid else { return false }

        do {
            let tokenResult = try await user.getIDTokenResult(forcingRefresh: true)
            return (tokenResult.claims[administratorClaim] as? Bool) == true
        } catch {
            #if DEBUG
            print("[AppSession] Falha ao validar perfil administrativo: \(error.localizedDescription)")
            #endif
            // Falha na validação nunca concede nem mantém privilégio administrativo
            return false
        }
    }
}

/// Dados do aparelho em uso, obtidos somente por APIs públicas do iOS.
/// - `model`: identificador técnico do hardware (ex.: "iPhone16,1"), sem conversão para nome comercial.
/// - `system`: nome e versão do sistema (ex.: "iOS 26.1").
/// - `identifier`: `identifierForVendor` — UUID por fornecedor/instalação; muda se todos os apps do
///   fornecedor forem removidos do aparelho. Não identifica o hardware nem permite rastreamento entre apps.
private struct UserDeviceInfo {
    let model: String?
    let system: String?
    let identifier: String?

    @MainActor
    static func current() -> UserDeviceInfo {
        let device = UIDevice.current
        let system = "\(device.systemName) \(device.systemVersion)".trimmingCharacters(in: .whitespacesAndNewlines)
        return UserDeviceInfo(
            model: sanitized(hardwareIdentifier()),
            system: sanitized(system),
            identifier: sanitized(device.identifierForVendor?.uuidString)
        )
    }

    private static func hardwareIdentifier() -> String? {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
        #endif
    }

    private static func sanitized(_ value: String?) -> String? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 64 else { return nil }
        return trimmed
    }
}

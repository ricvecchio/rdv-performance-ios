import Foundation
import SwiftUI
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


    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    private let administratorEmail = "ric.vecchio@gmail.com"

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
    var isLoggedIn: Bool {
        uid != nil && (userType != nil || isAdmin)
    }

    // Retorna o identificador único do usuário autenticado
    var currentUid: String? { uid }

    // Retorna o tipo de usuário em formato string
    var currentUserTypeRaw: String? { userType?.rawValue }

    // Retorna verdadeiro se o usuário é um aluno
    var isStudent: Bool {
        if isAdmin { return adminProfileMode == .student }
        userType?.rawValue.lowercased() == "student"
    }

    // Retorna verdadeiro se o usuário é um professor
    var isTrainer: Bool {
        if isAdmin { return adminProfileMode == .trainer }
        userType?.rawValue.lowercased() == "trainer"
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
                    self.isAdmin = self.isAuthenticatedAdministrator()
                    self.adminProfileMode = nil
                    self.storedUid = user.uid
                    await self.loadUserProfile(uid: user.uid)
                    await PersonalRecordsSyncService.shared.synchronizeForAuthenticatedUser(uid: user.uid)
                } else {
                    PersonalRecordsSyncService.shared.handleLogout()
                    self.clearSession()
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
        isAdmin = isAuthenticatedAdministrator()

        do {
            let snap = try await db.collection("users").document(uid).getDocument(source: .server)

            guard let data = snap.data() else {
                self.userType = nil
                self.userName = nil
                self.measurementUnitLoadState = .failed

                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                return
            }

            let name = data["name"] as? String
            let typeRaw = data["userType"] as? String
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

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

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
            print("[Settings] Falha ao carregar unidade de medida: \(error.localizedDescription)")
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
    }

    private func isAuthenticatedAdministrator() -> Bool {
        let email = (Auth.auth().currentUser?.email ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return email == administratorEmail
    }
}

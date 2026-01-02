import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {

    // MARK: - Persistência simples (AppStorage)
    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    // MARK: - Estado em memória (observável)
    // Mantive as propriedades como você já usa (evita quebrar bindings existentes).
    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // MARK: - Init / Deinit
    init() {
        // ✅ Estado inicial (útil se abrir offline e já tiver cache)
        self.uid = storedUid.isEmpty ? nil : storedUid
        self.userType = UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName

        observeAuthState()
    }

    deinit {
        // ✅ Boa prática: remover listener ao desalocar a sessão
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // MARK: - Computeds (base para roteamento por perfil)
    var isLoggedIn: Bool {
        uid != nil && userType != nil
    }

    /// UID “seguro” para consumo em Services/ViewModels (evita ficar desembrulhando optional toda hora).
    var currentUid: String? { uid }

    /// Tipo de conta em string (útil para logs/telemetria/debug sem expor storage).
    var currentUserTypeRaw: String? { userType?.rawValue }

    /// Conveniências que ajudam o AppRouter/Home/Footer a mostrar opções por perfil
    var isStudent: Bool {
        // Ajuste aqui caso seus rawValues sejam diferentes
        userType?.rawValue.lowercased() == "student"
    }

    var isTrainer: Bool {
        // Ajuste aqui caso seus rawValues sejam diferentes
        userType?.rawValue.lowercased() == "trainer"
    }

    // MARK: - Observa login/logout real do FirebaseAuth
    private func observeAuthState() {
        // Evita adicionar múltiplos listeners por acidente
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                if let user {
                    self.uid = user.uid
                    self.storedUid = user.uid

                    // ✅ Sempre buscar perfil no Firestore para saber userType/name
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.clearSession()
                }
            }
        }
    }

    // MARK: - Recarregar perfil (público, útil para Settings/Profile)
    func refreshProfile() async {
        guard let uid else { return }
        await loadUserProfile(uid: uid)
    }

    // MARK: - Carrega userType + name do Firestore (users/{uid})
    func loadUserProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()

            guard let data = snap.data() else {
                // Documento não existe (ainda não cadastrou o perfil) → limpa somente campos de perfil
                self.userType = nil
                self.userName = nil
                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                return
            }

            let name = data["name"] as? String
            let typeRaw = data["userType"] as? String // ✅ CORRETO (confirmado no Firebase)

            self.userName = name
            self.userType = typeRaw.flatMap { UserTypeDTO(rawValue: $0) }

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

        } catch {
            // ✅ Em erro de rede, mantém o que estiver armazenado.
            // Se quiser debugar, descomente:
            // print("⚠️ loadUserProfile error: \(error.localizedDescription)")
        }
    }

    // MARK: - Logout (Firebase + limpa storage)
    func logout() {
        do {
            try Auth.auth().signOut()
            // O listener deve receber "user = nil" e limpar a sessão,
            // mas mantemos redundância segura:
            clearSession()
        } catch {
            clearSession()
        }
    }

    // MARK: - Limpa sessão
    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }
}


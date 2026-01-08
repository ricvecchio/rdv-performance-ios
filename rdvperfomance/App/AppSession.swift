import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Gerencia o estado de autenticação e perfil do usuário no app
@MainActor
final class AppSession: ObservableObject {

    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    /// Inicializa a sessão e restaura estado persistido ou limpa em modo DEBUG
    init() {
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

    /// Retorna true se há um usuário autenticado
    var isLoggedIn: Bool {
        uid != nil && userType != nil
    }

    /// Retorna o UID do usuário atual
    var currentUid: String? { uid }

    /// Retorna o tipo de usuário em formato raw
    var currentUserTypeRaw: String? { userType?.rawValue }

    /// Retorna true se o usuário é um aluno
    var isStudent: Bool {
        userType?.rawValue.lowercased() == "student"
    }

    /// Retorna true se o usuário é um professor
    var isTrainer: Bool {
        userType?.rawValue.lowercased() == "trainer"
    }

    /// Configura observador de mudanças no estado de autenticação do Firebase
    private func observeAuthState() {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                if let user {
                    self.uid = user.uid
                    self.storedUid = user.uid
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.clearSession()
                }
            }
        }
    }

    /// Recarrega o perfil do usuário atual do Firestore
    func refreshProfile() async {
        guard let uid else { return }
        await loadUserProfile(uid: uid)
    }

    /// Carrega dados do perfil (nome e tipo) do Firestore
    func loadUserProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()

            guard let data = snap.data() else {
                self.userType = nil
                self.userName = nil
                self.storedUserTypeRaw = ""
                self.storedUserName = ""
                return
            }

            let name = data["name"] as? String
            let typeRaw = data["userType"] as? String

            self.userName = name
            self.userType = typeRaw.flatMap { UserTypeDTO(rawValue: $0) }

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

        } catch {
        }
    }

    /// Realiza logout do Firebase e limpa a sessão local
    func logout() {
        do {
            try Auth.auth().signOut()
            clearSession()
        } catch {
            clearSession()
        }
    }

    /// Limpa todos os dados de sessão do app
    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }
}

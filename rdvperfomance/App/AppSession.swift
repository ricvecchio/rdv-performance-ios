import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {

    // MARK: - Persistência simples
    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    // MARK: - Estado em memória
    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // ✅ Estado inicial (útil se abrir offline e já tiver cache)
        self.uid = storedUid.isEmpty ? nil : storedUid
        self.userType = UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName

        observeAuthState()
    }

    var isLoggedIn: Bool {
        uid != nil && userType != nil
    }

    // MARK: - Observa login/logout real do FirebaseAuth
    private func observeAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            Task { @MainActor in
                if let user {
                    self.uid = user.uid
                    self.storedUid = user.uid

                    // ✅ sempre buscar perfil no Firestore para saber userType/name
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.clearSession()
                }
            }
        }
    }

    // MARK: - Carrega userType + name do Firestore (users/{uid})
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
            let typeRaw = data["userType"] as? String // ✅ CORRETO (confirmado no Firebase)

            self.userName = name
            self.userType = typeRaw.flatMap { UserTypeDTO(rawValue: $0) }

            self.storedUserName = name ?? ""
            self.storedUserTypeRaw = self.userType?.rawValue ?? ""

            // Debug opcional:
            // print("✅ Perfil carregado: uid=\(uid), type=\(typeRaw ?? "-"), name=\(name ?? "-")")

        } catch {
            // Em erro de rede, mantém o que estiver armazenado
        }
    }

    // MARK: - Logout (Firebase + limpa storage)
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            clearSession()
        }
    }

    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }
}


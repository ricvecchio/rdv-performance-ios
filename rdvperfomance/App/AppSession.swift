// AppSession.swift — Sessão da aplicação: gerenciamento de autenticação e perfil do usuário
import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AppSession: ObservableObject {

    // Persistência simples via AppStorage
    @AppStorage("auth_uid") private var storedUid: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    // Estado observável em memória
    @Published var uid: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    private var authListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    // Init / Deinit: restaura estado e configura observador de autenticação
    init() {
        // Em builds de desenvolvimento, limpar sessão para forçar início no login facilita testes.
        // Em produção, mantemos o comportamento padrão (persistência de sessão).
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
            // Ignora erros de signOut (por exemplo, se não houver usuário)
        }
        #else
        // Em produção, restauramos o estado persistido (se houver)
        self.uid = storedUid.isEmpty ? nil : storedUid
        self.userType = storedUserTypeRaw.isEmpty ? nil : UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName
        #endif

        observeAuthState()
    }

    deinit {
        if let authListener {
            Auth.auth().removeStateDidChangeListener(authListener)
        }
    }

    // Computed: indica se há usuário logado
    var isLoggedIn: Bool {
        uid != nil && userType != nil
    }

    // Conveniência: UID atual
    var currentUid: String? { uid }

    // Conveniência: userType raw
    var currentUserTypeRaw: String? { userType?.rawValue }

    // Conveniências: checagens por tipo de conta
    var isStudent: Bool {
        userType?.rawValue.lowercased() == "student"
    }

    var isTrainer: Bool {
        userType?.rawValue.lowercased() == "trainer"
    }

    // Observa mudanças reais de autenticação do Firebase
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

                    // Busca perfil no Firestore
                    await self.loadUserProfile(uid: user.uid)
                } else {
                    self.clearSession()
                }
            }
        }
    }

    // Recarrega perfil do usuário de forma assíncrona
    func refreshProfile() async {
        guard let uid else { return }
        await loadUserProfile(uid: uid)
    }

    // Carrega userType e nome do Firestore
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
            // Em caso de erro, mantém o estado armazenado
        }
    }

    // Realiza logout no Firebase e limpa sessão local
    func logout() {
        do {
            try Auth.auth().signOut()
            clearSession()
        } catch {
            clearSession()
        }
    }

    // Limpa todos os dados de sessão locais
    private func clearSession() {
        uid = nil
        userType = nil
        userName = nil

        storedUid = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }
}

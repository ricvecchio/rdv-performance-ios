import Foundation
import SwiftUI
import Combine

@MainActor
final class AppSession: ObservableObject {

    // MARK: - Persistência simples
    @AppStorage("auth_token") private var storedToken: String = ""
    @AppStorage("auth_userType") private var storedUserTypeRaw: String = ""
    @AppStorage("auth_userName") private var storedUserName: String = ""

    // MARK: - Estado em memória
    @Published var token: String? = nil
    @Published var userType: UserTypeDTO? = nil
    @Published var userName: String? = nil

    // MARK: - Init
    init() {
        self.token = storedToken.isEmpty ? nil : storedToken
        self.userType = UserTypeDTO(rawValue: storedUserTypeRaw)
        self.userName = storedUserName.isEmpty ? nil : storedUserName
    }

    // MARK: - Computed
    var isLoggedIn: Bool {
        token != nil && userType != nil
    }

    // MARK: - Start session (real / backend)
    func start(token: String, userType: UserTypeDTO, userName: String?) {
        self.token = token
        self.userType = userType
        self.userName = userName

        storedToken = token
        storedUserTypeRaw = userType.rawValue
        storedUserName = userName ?? ""
    }

    // MARK: - Logout
    func logout() {
        token = nil
        userType = nil
        userName = nil

        storedToken = ""
        storedUserTypeRaw = ""
        storedUserName = ""
    }

    // ============================================================
    // MARK: - MOCK LOGIN (MVP)
    // Usuários fixos:
    // - Aluno:     ric@gmail.com / ric
    // - Professor: prof@gmail.com / prof
    // ============================================================

    private enum MockUsers {
        static let studentEmail = "ric@gmail.com"
        static let studentPass  = "ric"

        static let trainerEmail = "prof@gmail.com"
        static let trainerPass  = "prof"

        static let studentToken = "mock-token-student"
        static let trainerToken = "mock-token-trainer"
    }

    /// Login mockado para Aluno (útil para debug rápido)
    func loginMockStudent() {
        start(
            token: MockUsers.studentToken,
            userType: .STUDENT,
            userName: "Ricardo (Aluno)"
        )
    }

    /// Login mockado para Professor (útil para debug rápido)
    func loginMockTrainer() {
        start(
            token: MockUsers.trainerToken,
            userType: .TRAINER,
            userName: "Professor (Mock)"
        )
    }

    /// Valida credenciais mockadas e inicia sessão.
    /// Retorna `true` se logou; `false` se credenciais inválidas.
    func mockLogin(email: String, password: String) -> Bool {
        let e = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if e == MockUsers.studentEmail && p == MockUsers.studentPass {
            loginMockStudent()
            return true
        }

        if e == MockUsers.trainerEmail && p == MockUsers.trainerPass {
            loginMockTrainer()
            return true
        }

        return false
    }

    /// Se quiser exibir dica na UI (ex.: placeholder de teste)
    var mockCredentialsHint: String {
        "Aluno: \(MockUsers.studentEmail)/\(MockUsers.studentPass) • Professor: \(MockUsers.trainerEmail)/\(MockUsers.trainerPass)"
    }
}


// ViewModel para gerenciar estado e validação da tela de login
import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let service = FirebaseAuthService()

    // Valida campos e executa login, retorna true se bem-sucedido
    func submitLogin() async -> Bool {

        errorMessage = nil

        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailTrim.isEmpty else {
            errorMessage = "Informe seu e-mail."
            return false
        }

        guard !passTrim.isEmpty else {
            errorMessage = "Informe sua senha."
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.login(email: emailTrim, password: passTrim)
            return true
        } catch {
            errorMessage = "E-mail ou senha inválidos."
            return false
        }
    }
}

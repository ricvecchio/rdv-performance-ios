import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let service = AuthService()

    func submitLogin() async throws -> LoginResponseDTO {

        errorMessage = nil

        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailTrim.isEmpty else {
            errorMessage = "Informe seu e-mail."
            throw NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "E-mail vazio"])
        }

        guard !passTrim.isEmpty else {
            errorMessage = "Informe sua senha."
            throw NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey: "Senha vazia"])
        }

        isLoading = true
        defer { isLoading = false }

        return try await service.login(LoginRequestDTO(email: emailTrim, password: passTrim))
    }
}

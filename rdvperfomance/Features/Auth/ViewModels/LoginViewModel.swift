import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

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
            errorMessage = AppLocalization.string("auth.validation.email_required", locale: Self.localizationLocale)
            return false
        }

        guard !passTrim.isEmpty else {
            errorMessage = AppLocalization.string("auth.validation.password_required", locale: Self.localizationLocale)
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.login(email: emailTrim, password: passTrim)
            return true
        } catch {
            errorMessage = AppLocalization.string("auth.login.invalid_credentials", locale: Self.localizationLocale)
            return false
        }
    }
}

// Serviço para operações de segurança da conta como alteração e exclusão
import Foundation
import FirebaseAuth
import FirebaseFirestore

// Gerencia operações sensíveis de conta do usuário
final class AccountSecurityService {

    static let shared = AccountSecurityService()
    private init() {}
    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    // Erros específicos do serviço de segurança
    enum ServiceError: LocalizedError {
        case notLoggedIn
        case missingEmail
        case weakPassword
        case passwordMismatch
        case requiresRecentLogin
        case invalidCredential
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return AppLocalization.string("account_security.errors.login_required", locale: AccountSecurityService.localizationLocale)
            case .missingEmail:
                return AppLocalization.string("account_security.errors.email_missing", locale: AccountSecurityService.localizationLocale)
            case .weakPassword:
                return AppLocalization.string("account_security.errors.weak_password", locale: AccountSecurityService.localizationLocale)
            case .passwordMismatch:
                return AppLocalization.string("account_security.errors.password_mismatch", locale: AccountSecurityService.localizationLocale)
            case .requiresRecentLogin:
                return AppLocalization.string("account_security.errors.reauthentication_required", locale: AccountSecurityService.localizationLocale)
            case .invalidCredential:
                return AppLocalization.string("account_security.errors.invalid_current_password", locale: AccountSecurityService.localizationLocale)
            case .unknown(let msg):
                return msg
            }
        }
    }

    // Altera a senha do usuário após validar credenciais atuais
    func changePassword(currentPassword: String, newPassword: String) async throws {

        let currentPasswordTrim = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPasswordTrim = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let user = Auth.auth().currentUser else { throw ServiceError.notLoggedIn }
        guard let email = user.email, !email.isEmpty else { throw ServiceError.missingEmail }

        guard newPasswordTrim.count >= 6 else { throw ServiceError.weakPassword }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPasswordTrim)

        do {
            _ = try await user.reauthenticate(with: credential)
            try await user.updatePassword(to: newPasswordTrim)
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // Exclui a conta do usuário após validação e remove dados do Firestore
    func deleteAccount(currentPassword: String) async throws {

        let currentPasswordTrim = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let user = Auth.auth().currentUser else { throw ServiceError.notLoggedIn }
        guard let uid = user.uid as String?, !uid.isEmpty else { throw ServiceError.notLoggedIn }
        guard let email = user.email, !email.isEmpty else { throw ServiceError.missingEmail }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPasswordTrim)

        do {
            _ = try await user.reauthenticate(with: credential)

            let db = Firestore.firestore()
            try await db.collection("users").document(uid).delete()

            try await user.delete()

        } catch {
            throw mapFirebaseError(error)
        }
    }

    // Converte erros do Firebase em erros do serviço com mensagens legíveis
    private func mapFirebaseError(_ error: Error) -> Error {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain {
            switch ns.code {
            case AuthErrorCode.wrongPassword.rawValue:
                return ServiceError.invalidCredential
            case AuthErrorCode.requiresRecentLogin.rawValue:
                return ServiceError.requiresRecentLogin
            case AuthErrorCode.weakPassword.rawValue:
                return ServiceError.weakPassword
            default:
                return ServiceError.unknown(ns.localizedDescription)
            }
        }
        return ServiceError.unknown(error.localizedDescription)
    }
}

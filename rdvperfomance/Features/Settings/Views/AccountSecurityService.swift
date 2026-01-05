import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - AccountSecurityService
final class AccountSecurityService {

    static let shared = AccountSecurityService()
    private init() {}

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
                return "Você precisa estar logado para realizar esta ação."
            case .missingEmail:
                return "Não foi possível identificar o e-mail do usuário logado."
            case .weakPassword:
                return "A nova senha é muito fraca. Use pelo menos 6 caracteres."
            case .passwordMismatch:
                return "As senhas não conferem."
            case .requiresRecentLogin:
                return "Por segurança, faça login novamente e tente de novo."
            case .invalidCredential:
                return "Senha atual inválida."
            case .unknown(let msg):
                return msg
            }
        }
    }

    // MARK: - Change Password (reauth + updatePassword)
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

    // MARK: - Delete Account (reauth + delete firestore profile + delete auth user)
    func deleteAccount(currentPassword: String) async throws {

        let currentPasswordTrim = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let user = Auth.auth().currentUser else { throw ServiceError.notLoggedIn }
        guard let uid = user.uid as String?, !uid.isEmpty else { throw ServiceError.notLoggedIn }
        guard let email = user.email, !email.isEmpty else { throw ServiceError.missingEmail }

        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPasswordTrim)

        do {
            _ = try await user.reauthenticate(with: credential)

            // 1) Remove perfil principal no Firestore (users/{uid})
            let db = Firestore.firestore()
            try await db.collection("users").document(uid).delete()

            // 2) Remove usuário do Auth (encerra sessão)
            try await user.delete()

        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Error mapping
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

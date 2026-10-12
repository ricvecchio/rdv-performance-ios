// ViewModel do gerenciamento do código de autorização para cadastro de professores
import Foundation
import Combine
import UIKit
import UniformTypeIdentifiers

@MainActor
final class TeacherAuthorizationCodeViewModel: ObservableObject {
    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    // Mantido apenas em memória enquanto a tela estiver aberta
    @Published private(set) var currentCode: TeacherAuthorizationCode?
    @Published private(set) var isLoading = false
    @Published private(set) var isRotating = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let service: TeacherAuthorizationService

    init(service: TeacherAuthorizationService? = nil) {
        self.service = service ?? TeacherAuthorizationService()
    }

    var isBusy: Bool { isLoading || isRotating }

    // Consulta o código vigente no backend (autorização verificada no servidor)
    func load() async {
        guard !isBusy else { return }
        errorMessage = nil
        successMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            currentCode = try await service.fetchCurrentCode()
        } catch {
            currentCode = nil
            errorMessage = Self.message(for: error)
        }
    }

    // Gera um novo código; o anterior deixa de funcionar imediatamente
    func rotate() async {
        guard !isBusy else { return }
        errorMessage = nil
        successMessage = nil
        isRotating = true
        defer { isRotating = false }

        do {
            currentCode = try await service.rotateCode()
            successMessage = AppLocalization.string("teacher_authorization.admin.rotated", locale: Self.localizationLocale)
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    // Copia o código apenas para este dispositivo, com expiração automática
    func copyCode() {
        guard let code = currentCode?.code else { return }

        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: code]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(120)
            ]
        )

        errorMessage = nil
        successMessage = AppLocalization.string("teacher_authorization.admin.copied", locale: Self.localizationLocale)
    }

    func clear() {
        currentCode = nil
        errorMessage = nil
        successMessage = nil
    }

    private static func message(for error: Error) -> String {
        if let authorizationError = error as? TeacherAuthorizationError {
            return authorizationError.localizedDescription
        }
        return TeacherAuthorizationError.unknown.localizedDescription
    }
}


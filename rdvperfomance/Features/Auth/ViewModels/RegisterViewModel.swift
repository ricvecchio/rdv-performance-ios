import Foundation
import Combine

@MainActor
final class RegisterViewModel: ObservableObject {

    // Campos comuns
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var phone: String = ""

    @Published var focusArea: FocusAreaDTO = .CROSSFIT
    @Published var planType: PlanTypeDTO = .FREE

    // Campos do treinador
    @Published var cref: String = ""
    @Published var bio: String = ""
    @Published var gymName: String = ""

    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    private let service = AuthService()

    func submit(userType: UserTypeDTO) async {
        errorMessage = nil
        successMessage = nil

        let nameTrim = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneTrim = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nameTrim.isEmpty else { errorMessage = "Informe seu nome."; return }
        guard !emailTrim.isEmpty else { errorMessage = "Informe seu e-mail."; return }
        guard !passTrim.isEmpty else { errorMessage = "Informe sua senha."; return }

        if userType == .TRAINER {
            let crefTrim = cref.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !crefTrim.isEmpty else { errorMessage = "Informe seu CREF."; return }
        }

        isLoading = true
        defer { isLoading = false }

        let dto = RegisterRequestDTO(
            name: nameTrim,
            email: emailTrim,
            password: passTrim,
            phone: phoneTrim.isEmpty ? nil : phoneTrim,
            userType: userType,
            focusArea: focusArea,
            planType: planType,
            cref: userType == .TRAINER ? cref.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            bio: userType == .TRAINER ? bio.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            gymName: userType == .TRAINER ? gymName.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        )

        do {
            let response = try await service.register(dto)
            successMessage = response.message ?? "Cadastro realizado com sucesso."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}


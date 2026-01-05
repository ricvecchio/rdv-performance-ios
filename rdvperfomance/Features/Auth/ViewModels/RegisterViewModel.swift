// RegisterViewModel.swift — ViewModel para cadastro de usuários (student/trainer)
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class RegisterViewModel: ObservableObject {

    // Campos de formulário
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var phone: String = ""

    @Published var focusArea: FocusAreaDTO = .CROSSFIT
    @Published var planType: PlanTypeDTO = .FREE

    // Campos do TRAINER
    @Published var cref: String = ""
    @Published var bio: String = ""
    @Published var gymName: String = ""

    // UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    private let service = FirebaseAuthService()
    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    // Valida e submete o cadastro para o Auth e Firestore
    func submit(userType: UserTypeDTO) async {
        errorMessage = nil
        successMessage = nil

        let nameTrim = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
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

        let form = RegisterFormDTO(
            name: nameTrim,
            email: emailTrim,
            password: passTrim,
            phone: phoneTrim.isEmpty ? nil : phoneTrim,
            userType: userType,
            focusArea: focusArea.rawValue,
            planType: planType.rawValue,
            cref: userType == .TRAINER ? cref.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            bio: userType == .TRAINER ? bio.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            gymName: userType == .TRAINER ? gymName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            defaultCategory: userType == .STUDENT ? "crossfit" : nil,
            active: userType == .STUDENT ? true : nil
        )

        do {
            // 1) cria no Firebase Auth
            let createdUid: String = try await service.register(form)

            // 2) grava perfil no Firestore (/users/{uid})
            do {
                try await repository.upsertUserProfile(
                    uid: createdUid,
                    form: form
                )
                successMessage = "Cadastro realizado com sucesso."
            } catch {
                let msg = (error as NSError).localizedDescription
                errorMessage = """
                Usuário criado no Auth, mas falhou ao salvar no Firestore.
                Motivo: \(msg)
                Verifique as regras do Firestore.
                """
            }

        } catch {
            let ns = error as NSError
            errorMessage = "Falha ao cadastrar no Auth. Motivo: \(ns.localizedDescription)"
        }
    }

    // Limpa mensagens de erro/sucesso
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

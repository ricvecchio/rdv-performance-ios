// ViewModel para gerenciar cadastro de alunos e professores
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class RegisterViewModel: ObservableObject {

    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var phone: String = ""

    @Published var focusArea: FocusAreaDTO = .CROSSFIT

    @Published var cref: String = ""
    @Published var bio: String = ""
    @Published var gymName: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    private let service = FirebaseAuthService()
    private let repository: FirestoreRepository

    // Inicializa com repositório Firestore injetado
    init(repository: FirestoreRepository? = nil) {
        self.repository = repository ?? .shared
    }

    // Valida formulário e cria usuário no Firebase Auth e Firestore
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
            cref: userType == .TRAINER ? cref.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            bio: userType == .TRAINER ? bio.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            gymName: userType == .TRAINER ? gymName.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            defaultCategory: userType == .STUDENT ? "crossfit" : nil,
            active: userType == .STUDENT ? true : nil
        )

        do {
            let createdUid: String = try await service.register(form)

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

    // Limpa mensagens de erro e sucesso exibidas na tela
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

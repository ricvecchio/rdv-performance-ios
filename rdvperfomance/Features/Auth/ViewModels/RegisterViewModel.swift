// ViewModel para gerenciar cadastro de alunos e professores
import Foundation
import Combine
import FirebaseAuth

@MainActor
final class RegisterViewModel: ObservableObject {
    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

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
        let phoneTrim = BrazilianPhoneFormatter.normalize(phone)

        let crefTrim = cref.trimmingCharacters(in: .whitespacesAndNewlines)
        let bioTrim = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        let gymNameTrim = gymName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nameTrim.isEmpty else { errorMessage = String(localized: "Informe seu nome.", locale: Self.localizationLocale); return }
        guard !emailTrim.isEmpty else { errorMessage = String(localized: "Informe seu e-mail.", locale: Self.localizationLocale); return }
        guard !passTrim.isEmpty else { errorMessage = String(localized: "Informe sua senha.", locale: Self.localizationLocale); return }
        guard BrazilianPhoneFormatter.isValidMobile(phoneTrim) else {
            errorMessage = String(localized: "Informe um WhatsApp com 11 dígitos.", locale: Self.localizationLocale)
            return
        }

        // ✅ Ajuste solicitado: CREF não é obrigatório para professor.
        // Se estiver vazio, será salvo como nil (não grava string vazia).
        let crefValueForTrainer: String? = {
            guard userType == .TRAINER else { return nil }
            return crefTrim.isEmpty ? nil : crefTrim
        }()

        let form = RegisterFormDTO(
            name: nameTrim,
            email: emailTrim,
            password: passTrim,
            phone: phoneTrim.isEmpty ? nil : phoneTrim,
            userType: userType,
            focusArea: focusArea.rawValue,
            cref: crefValueForTrainer,
            bio: userType == .TRAINER ? (bioTrim.isEmpty ? nil : bioTrim) : nil,
            gymName: userType == .TRAINER ? (gymNameTrim.isEmpty ? nil : gymNameTrim) : nil,
            defaultCategory: userType == .STUDENT ? "crossfit" : nil,
            active: userType == .STUDENT ? true : nil
        )

        isLoading = true
        defer { isLoading = false }

        do {
            let createdUid: String = try await service.register(form)

            do {
                try await repository.upsertUserProfile(
                    uid: createdUid,
                    form: form
                )
                successMessage = String(localized: "Cadastro realizado com sucesso.", locale: Self.localizationLocale)
            } catch {
                let msg = (error as NSError).localizedDescription
                let format = String(
                    localized: "Usuário criado no Auth, mas falhou ao salvar no Firestore.\nMotivo: %@\nVerifique as regras do Firestore.",
                    locale: Self.localizationLocale
                )
                errorMessage = String(format: format, locale: Self.localizationLocale, arguments: [msg])
            }

        } catch {
            let ns = error as NSError
            let format = String(localized: "Falha ao cadastrar no Auth. Motivo: %@", locale: Self.localizationLocale)
            errorMessage = String(
                format: format,
                locale: Self.localizationLocale,
                arguments: [ns.localizedDescription]
            )
        }
    }

    // Limpa mensagens de erro e sucesso exibidas na tela
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

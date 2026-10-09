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
    private let teacherAuthorizationService = TeacherAuthorizationService()
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

        guard !nameTrim.isEmpty else { errorMessage = AppLocalization.string("auth.validation.name_required", locale: Self.localizationLocale); return }
        guard !emailTrim.isEmpty else { errorMessage = AppLocalization.string("auth.validation.email_required", locale: Self.localizationLocale); return }
        guard !passTrim.isEmpty else { errorMessage = AppLocalization.string("auth.validation.password_required", locale: Self.localizationLocale); return }
        guard BrazilianPhoneFormatter.isValidMobile(phoneTrim) else {
            errorMessage = AppLocalization.string("auth.validation.whatsapp_invalid", locale: Self.localizationLocale)
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

        // Cadastro de professor exige autorização validada e é efetivado no backend
        if userType == .TRAINER {
            await submitAuthorizedTrainer(form: form)
            return
        }

        do {
            let createdUid: String = try await service.register(form)

            do {
                try await repository.upsertUserProfile(
                    uid: createdUid,
                    form: form
                )
                successMessage = AppLocalization.string("auth.registration.success", locale: Self.localizationLocale)
            } catch {
                let msg = (error as NSError).localizedDescription
                let format = AppLocalization.string("auth.registration.firestore_profile_save_failed",
                    locale: Self.localizationLocale
                )
                errorMessage = String(format: format, locale: Self.localizationLocale, arguments: [msg])
            }

        } catch {
            let ns = error as NSError
            let format = AppLocalization.string("auth.registration.authentication_failed", locale: Self.localizationLocale)
            errorMessage = String(
                format: format,
                locale: Self.localizationLocale,
                arguments: [ns.localizedDescription]
            )
        }
    }

    // Cria a conta de professor pela Cloud Function, que valida e consome a autorização
    private func submitAuthorizedTrainer(form: RegisterFormDTO) async {
        let authorizationStore = TeacherSignupAuthorizationStore.shared

        guard let ticket = authorizationStore.ticket else {
            errorMessage = TeacherAuthorizationError.authorizationRequired.localizedDescription
            return
        }

        do {
            _ = try await teacherAuthorizationService.createTeacherAccount(ticket: ticket, form: form)
            authorizationStore.clear()
        } catch let error as TeacherAuthorizationError {
            if error == .authorizationExpired {
                authorizationStore.clear()
            }
            errorMessage = error.localizedDescription
            return
        } catch {
            errorMessage = TeacherAuthorizationError.unknown.localizedDescription
            return
        }

        // A conta já foi criada no backend; autentica para manter o comportamento anterior.
        // Em caso de falha no login automático, o usuário retorna ao login e entra manualmente.
        _ = try? await service.login(email: form.email, password: form.password)
        successMessage = AppLocalization.string("auth.registration.success", locale: Self.localizationLocale)
    }

    // Limpa mensagens de erro e sucesso exibidas na tela
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

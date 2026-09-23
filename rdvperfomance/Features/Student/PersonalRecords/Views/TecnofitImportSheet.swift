import SwiftUI

struct TecnofitImportSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    let onImportCompleted: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var preview: TecnofitImportPreview?
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let service = TecnofitImportService()
    private let repository = FirestoreRepository.shared

    var body: some View {
        ZStack {
            Theme.Colors.headerBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 5)
                            .padding(.top, 10)

                        Text("Importar do Tecnofit")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        importCard
                            .padding(.horizontal, 16)
                            .padding(.top, 14)
                    }
                }

                HStack(spacing: 12) {
                    cancelButton
                    actionButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .presentationDetents([.fraction(2.0 / 3.0)])
        .onDisappear(perform: clearPassword)
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Conecte sua conta para buscar recordes da unidade CrossFit. Seus recordes já existentes serão preservados.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.45))

            credentialsFields

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(.green)
                    Text("Buscando recordes...")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            if let errorMessage {
                messageText(errorMessage, color: .yellow.opacity(0.85))
            }

            if let preview {
                summaryCard(preview)
            }

            if let successMessage {
                messageText(successMessage, color: .green.opacity(0.85))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var credentialsFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            credentialField(
                title: "E-mail",
                field: AnyView(
                    TextField("", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                )
            )

            credentialField(
                title: "Senha",
                field: AnyView(
                    SecureField("", text: $password)
                        .textContentType(.password)
                )
            )
        }
    }

    private func credentialField(title: String, field: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))

            field
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.10))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func summaryCard(_ preview: TecnofitImportPreview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumo da importação")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            summaryLine("\(preview.recordsReady) recorde(s) pronto(s) para importar", icon: "checkmark.circle.fill", color: .green)
            summaryLine("\(preview.conflictsPreserved) recorde(s) existente(s) preservado(s)", icon: "shield.fill", color: .orange)
            summaryLine("\(preview.unmatchedSkipped) item(ns) sem mapeamento compatível ignorado(s)", icon: "arrow.uturn.forward.circle", color: .white.opacity(0.65))
        }
    }

    private func summaryLine(_ text: String, icon: String, color: Color) -> some View {
        Label {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.82))
        } icon: {
            Image(systemName: icon).foregroundColor(color)
        }
    }

    private var actionButton: some View {
        Button {
            if preview == nil {
                fetchRecords()
            } else {
                importRecords()
            }
        } label: {
            Text(preview == nil ? "Buscar recordes" : "Importar")
                .frame(maxWidth: .infinity)
                .primaryGreenActionButton()
        }
        .buttonStyle(.plain)
        .disabled(isLoading || (preview != nil && preview?.recordsReady == 0))
        .opacity((isLoading || (preview != nil && preview?.recordsReady == 0)) ? 0.55 : 1)
    }

    private var cancelButton: some View {
        Button {
            clearPassword()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "xmark")
                Text("Cancelar")
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.10))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func messageText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fetchRecords() {
        guard let uid = session.currentUid, !uid.isEmpty else {
            errorMessage = "Sua sessão não está disponível para importar recordes."
            return
        }

        let submittedEmail = email
        var submittedPassword = password
        password = ""
        errorMessage = nil
        successMessage = nil
        preview = nil
        isLoading = true

        Task { @MainActor in
            defer {
                submittedPassword = ""
                isLoading = false
            }
            do {
                preview = try await service.fetchPreview(
                    sessionAccount: uid,
                    email: submittedEmail,
                    password: submittedPassword
                )
            } catch let error as LocalizedError {
                errorMessage = error.errorDescription ?? TecnofitImportError.unavailable.errorDescription
            } catch {
                errorMessage = TecnofitImportError.unavailable.errorDescription
            }
        }
    }

    private func importRecords() {
        guard let preview,
              let uid = session.currentUid,
              !uid.isEmpty
        else {
            errorMessage = "Sua sessão não está disponível para importar recordes."
            return
        }

        let imported = TecnofitPersonalRecordsImporter.apply(preview)
        self.preview = nil

        Task { @MainActor in
            do {
                try await repository.markTecnofitImportCompleted(uid: uid)
                successMessage = imported > 0
                    ? "\(imported) recorde(s) importado(s) com sucesso."
                    : "Nenhum recorde foi alterado; os registros existentes foram preservados."
                onImportCompleted()
            } catch {
                errorMessage = "Não foi possível concluir a importação. Tente novamente."
            }
        }
    }

    private func clearPassword() {
        password = ""
    }
}

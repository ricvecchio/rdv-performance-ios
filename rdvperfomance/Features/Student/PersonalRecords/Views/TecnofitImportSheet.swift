import SwiftUI

struct TecnofitImportSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
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

                        Text("personal_records.import_from_tecnofit")
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
            Text("tecnofit_import.connect_your_account_to_fetch_records_from_the_crossfit_location_your_existing_records_will_be_preserved")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.45))

            credentialsFields

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(.green)
                    Text("tecnofit_import.fetching_records")
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
                title: "common.email",
                field: AnyView(
                    TextField("", text: $email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                )
            )

            credentialField(
                title: "common.password",
                field: AnyView(
                    SecureField("", text: $password)
                        .textContentType(.password)
                )
            )
        }
    }

    private func credentialField(title: LocalizedStringKey, field: AnyView) -> some View {
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
            Text("tecnofit_import.import_summary")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            summaryLine(
                recordsReadyText(preview.recordsReady),
                icon: "checkmark.circle.fill",
                color: .green
            )
            summaryLine(
                conflictsPreservedText(preview.conflictsPreserved),
                icon: "shield.fill",
                color: .orange
            )
            summaryLine(
                unmatchedSkippedText(preview.unmatchedSkipped),
                icon: "arrow.uturn.forward.circle",
                color: .white.opacity(0.65)
            )
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
            Text(
                preview == nil
                    ? String(localized: "tecnofit_import.fetch_records", locale: locale)
                    : String(localized: "tecnofit_import.import_action", locale: locale)
            )
                .frame(maxWidth: .infinity)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(actionButtonIsEnabled ? .white.opacity(0.92) : .white.opacity(0.55))
                .padding(.vertical, 14)
                .background(
                    actionButtonIsEnabled
                        ? Theme.Colors.primaryGreen.opacity(0.24)
                        : Color.white.opacity(0.10)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            actionButtonIsEnabled
                                ? Theme.Colors.primaryGreen.opacity(0.36)
                                : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(!actionButtonIsEnabled)
        .opacity(actionButtonIsEnabled ? 1 : 0.55)
    }

    private var actionButtonIsEnabled: Bool {
        guard !isLoading else { return false }

        if let preview {
            return preview.recordsReady > 0
        }

        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var cancelButton: some View {
        Button {
            clearPassword()
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "xmark")
                Text("common.cancel")
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
            errorMessage = String(
                localized: "tecnofit_import.session_unavailable",
                locale: locale
            )
            return
        }

        let submittedEmail = email
        var submittedPassword = password
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
            errorMessage = String(
                localized: "tecnofit_import.session_unavailable",
                locale: locale
            )
            return
        }

        let imported = TecnofitPersonalRecordsImporter.apply(preview)
        self.preview = nil

        Task { @MainActor in
            do {
                try await repository.markTecnofitImportCompleted(uid: uid)
                successMessage = imported > 0
                    ? importedRecordsText(imported)
                    : String(
                        localized: "tecnofit_import.no_records_changed",
                        locale: locale
                    )
                onImportCompleted()
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            } catch {
                errorMessage = String(
                    localized: "tecnofit_import.import_error",
                    locale: locale
                )
            }
        }
    }

    private func clearPassword() {
        password = ""
    }

    private func recordsReadyText(_ count: Int) -> String {
        let format = count == 1
            ? String(localized: "tecnofit_import.records_ready_singular", locale: locale)
            : String(localized: "tecnofit_import.records_ready_plural", locale: locale)
        return String(format: format, locale: locale, arguments: [Int64(count)])
    }

    private func conflictsPreservedText(_ count: Int) -> String {
        let format = count == 1
            ? String(localized: "tecnofit_import.existing_records_preserved_singular", locale: locale)
            : String(localized: "tecnofit_import.existing_records_preserved_plural", locale: locale)
        return String(format: format, locale: locale, arguments: [Int64(count)])
    }

    private func unmatchedSkippedText(_ count: Int) -> String {
        let format = count == 1
            ? String(localized: "tecnofit_import.unmapped_items_skipped_singular", locale: locale)
            : String(localized: "tecnofit_import.unmapped_items_skipped_plural", locale: locale)
        return String(format: format, locale: locale, arguments: [Int64(count)])
    }

    private func importedRecordsText(_ count: Int) -> String {
        let format = count == 1
            ? String(localized: "tecnofit_import.records_imported_singular", locale: locale)
            : String(localized: "tecnofit_import.records_imported_plural", locale: locale)
        return String(format: format, locale: locale, arguments: [Int64(count)])
    }

}

// Tela para exclusão permanente da conta do usuário
import SwiftUI

// View para exclusão de conta com confirmação rigorosa
struct DeleteAccountView: View {

    @Binding var path: [AppRoute]
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
    }
    @EnvironmentObject private var session: AppSession
    @Environment(\.locale) private var locale

    @State private var currentPassword: String = ""
    @State private var confirmText: String = ""

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)
    private let contentMaxWidth: CGFloat = 380

    // Retorna verdadeiro se pode executar a exclusão
    private var canDelete: Bool {
        !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && confirmText.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(confirmationKeyword) == .orderedSame
        && !isLoading
    }

    private var confirmationKeyword: String {
        AppLocalization.string("settings.delete.confirmation_keyword", locale: locale)
    }

    // Constrói a interface com aviso, formulário e ações
    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {

                            warningCard()
                            formCard()
                            deleteAccountButton()

                            if showError {
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.Colors.ink(0.95))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.25))
                                    .cornerRadius(12)
                            }

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundStyle(Theme.Colors.systemAccentForeground())
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            ToolbarItem(placement: .principal) {
                Text("settings.delete.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
    }

    // Retorna card de aviso sobre a ação permanente
    private func warningCard() -> some View {
        VStack(spacing: 10) {

            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red.opacity(0.9))
                Text("common.warning")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                Spacer()
            }

            Text("settings.delete.warning_message")
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.ink(0.60))
                .multilineTextAlignment(.leading)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    // Retorna formulário com senha e confirmação
    private func formCard() -> some View {
        VStack(spacing: 18) {

            secureUnderlineField(title: "settings.password.current", text: $currentPassword)

            underlineField(
                title: (
                    Text("settings.delete.confirm_prefix").foregroundStyle(AppThemeAdaptiveColor(textSecondary))
                    + Text(confirmationKeyword).bold().foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                    + Text("settings.delete.confirm_suffix").foregroundStyle(AppThemeAdaptiveColor(textSecondary))
                )
                .font(.system(size: 14)),
                text: $confirmText
            )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.border), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    private func deleteAccountButton() -> some View {
        Button {
            Task { await submitDelete() }
        } label: {
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                    Text(
                        isLoading
                            ? LocalizedStringKey("settings.delete.loading")
                            : LocalizedStringKey("settings.delete.submit")
                    )
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                Spacer()
            }
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.28))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canDelete)
    }

    // Valida e submete a exclusão da conta
    private func submitDelete() async {
        showError = false
        errorMessage = ""

        guard session.isLoggedIn else {
            presentError("auth.errors.login_required")
            return
        }

        let pw = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pw.isEmpty else {
            presentError("settings.delete.current_password_required")
            return
        }

        guard confirmText.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(confirmationKeyword) == .orderedSame else {
            let format = AppLocalization.string("settings.delete.confirmation_required", locale: locale)
            presentError(
                String(
                    format: format,
                    locale: locale,
                    arguments: [confirmationKeyword]
                )
            )
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AccountSecurityService.shared.deleteAccount(currentPassword: pw)

            // Após deletar, limpa caminho para forçar flow de login
            path.removeAll()

        } catch {
            presentError(error.localizedDescription)
        }
    }

    // Exibe mensagem de erro na interface
    private func presentError(_ message: String) {
        showError = true
        errorMessage = message
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Retorna campo de texto com linha inferior
    private func underlineField(title: Text, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            title

            TextField("", text: text)
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                .font(.system(size: 16))
                .padding(.vertical, 10)

            Rectangle()
                .fill(AppThemeAdaptiveColor(lineColor))
                .frame(height: 1)
        }
    }

    // Retorna campo seguro com linha inferior
    private func secureUnderlineField(title: LocalizedStringKey, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(AppThemeAdaptiveColor(textSecondary))

            SecureField("", text: text)
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(.vertical, 10)

            Rectangle()
                .fill(AppThemeAdaptiveColor(lineColor))
                .frame(height: 1)
        }
    }
}

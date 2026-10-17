// Tela para alteração de senha do usuário
import SwiftUI

// View para o usuário alterar sua senha com validação
struct ChangePasswordView: View {

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

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)
    private let contentMaxWidth: CGFloat = 380
    @Environment(\.locale) private var locale

    // Constrói a interface da tela de alteração de senha
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

                            formCard()
                            savePasswordButton()

                            if showError {
                                feedbackCard(text: errorMessage, isError: true)
                            }

                            if showSuccess {
                                feedbackCard(
                                    text: AppLocalization.string("settings.password.changed_success", locale: locale),
                                    isError: false
                                )
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
            }

            ToolbarItem(placement: .principal) {
                Text("settings.password.title")
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

    // Retorna card com campos de senha
    private func formCard() -> some View {
        VStack(spacing: 18) {

            secureUnderlineField(title: "settings.password.current", text: $currentPassword)
            secureUnderlineField(title: "settings.password.new", text: $newPassword)
            secureUnderlineField(title: "settings.password.confirm", text: $confirmNewPassword)
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

    private func savePasswordButton() -> some View {
        Button {
            Task { await submit() }
        } label: {
            if appTheme == .light && !isLoading {
                // Tema Claro (habilitado): mesmo padrão de cores do botão Sair da ProfileView, com as dimensões do `primaryGreenActionButton()`
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .foregroundStyle(Color.white)
                        Text("settings.password.save")
                    }
                    Spacer()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppThemePalette.lightBar.opacity(0.90), lineWidth: 1)
                )
            } else {
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .appThemeIconForeground()
                        Text(
                            isLoading
                                ? LocalizedStringKey("common.saving")
                                : LocalizedStringKey("settings.password.save")
                        )
                    }
                    Spacer()
                }
                .primaryGreenActionButton()
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    // Retorna card de feedback de sucesso ou erro
    private func feedbackCard(text: String, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.Colors.ink(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background((isError ? Color.red : Color.green).opacity(0.20))
            .cornerRadius(12)
    }

    // Valida e submete a alteração de senha
    private func submit() async {
        showError = false
        showSuccess = false
        errorMessage = ""

        let cp = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let np = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let cn = confirmNewPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard session.isLoggedIn else {
            presentError(AppLocalization.string("auth.errors.login_required", locale: locale))
            return
        }

        guard !cp.isEmpty, !np.isEmpty, !cn.isEmpty else {
            presentError(AppLocalization.string("settings.password.fill_all", locale: locale))
            return
        }

        guard np.count >= 6 else {
            presentError(AppLocalization.string("settings.password.min_length", locale: locale))
            return
        }

        guard np == cn else {
            presentError(AppLocalization.string("settings.password.confirmation_mismatch", locale: locale))
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AccountSecurityService.shared.changePassword(currentPassword: cp, newPassword: np)

            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            showSuccess = true

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

    // Retorna campo seguro com linha inferior
    private func secureUnderlineField(
        title: LocalizedStringKey,
        text: Binding<String>
    ) -> some View {
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

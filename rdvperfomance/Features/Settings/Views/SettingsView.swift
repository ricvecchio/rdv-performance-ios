import SwiftUI

// Tela de configurações do aplicativo
struct SettingsView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
    }

    private let contentMaxWidth: CGFloat = 380

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Constrói a interface da tela de configurações
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

                        VStack(alignment: .leading, spacing: 16) {

                            sectionTitle("settings.section.account")
                            accountCard()

                            sectionTitle("settings.section.preferences")
                            preferencesCard()

                            sectionTitle("settings.section.support_legal")
                            supportLegalCard()

                            Color.clear.frame(height: 16)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

                footerForUser()
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
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
                Text("settings.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }
        }

        // Cor explícita dependente de `appTheme`: atualiza a barra imediatamente ao alternar o tema
        .toolbarBackground(Theme.Colors.headerBackgroundColor(for: appTheme), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .navigationBarTitleDisplayMode(.inline)

    }

    @ViewBuilder
    private func footerForUser() -> some View {
        if session.isStudent {
            FooterBar(
                path: $path,
                kind: .studentHomeTreinosRecordsProfile(
                    isHomeSelected: false,
                    isTreinosSelected: false,
                    isRecordsSelected: false,
                    isPerfilSelected: false
                )
            )
        } else {
            FooterBar(
                path: $path,
                kind: .teacherHomeAlunosSobrePerfil(
                    selectedCategory: categoriaAtualProfessor,
                    isHomeSelected: false,
                    isAlunosSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: true
                )
            )
        }
    }

    // Volta uma tela usando dismiss nativo do SwiftUI. Como Settings é
    // sempre apresentado por NavigationStack, esse é o pop mais confiável
    // para evitar toque perdido por mutação manual de `path`.
    private func pop() {
        dismiss()
    }

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.Colors.ink(0.35))
            .padding(.horizontal, 6)
    }

    private func accountCard() -> some View {
        card {
            cardRow(icon: "person.crop.circle", title: "auth.edit_profile.title") {
                path.append(.editarPerfil)
            }
            divider()
            cardRow(icon: "key.fill", title: "settings.password.title") {
                path.append(.alterarSenha)
            }
            divider()
            cardRow(icon: "trash.fill", title: "settings.delete.title") {
                path.append(.excluirConta)
            }
        }
    }

    private func preferencesCard() -> some View {
        card {
            cardRow(icon: "globe", title: "settings.language.title") {
                path.append(.idioma)
            }
            divider()
            cardRow(icon: "circle.lefthalf.filled", title: "settings.theme.title") {
                path.append(.tema)
            }
        }
    }

    private func supportLegalCard() -> some View {
        card {

            cardRow(icon: "info.circle.fill", title: "settings.about") {
                path.append(.sobre)
            }

            divider()

            cardRow(icon: "questionmark.circle.fill", title: "settings.help_center") {
                path.append(.infoLegal(.helpCenter))
            }
            divider()
            cardRow(icon: "hand.raised.fill", title: "settings.privacy_policy") {
                path.append(.infoLegal(.privacyPolicy))
            }
            divider()
            cardRow(icon: "doc.text.fill", title: "settings.terms_of_use") {
                path.append(.infoLegal(.termsOfUse))
            }
            divider()

            cardRow(icon: "gamecontroller.fill", title: "settings.progress_preview") {
                path.append(.spriteDemo)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.vertical, 8)
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

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 54)
    }

    private func cardRow(icon: String, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Colors.chevron(0.35))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

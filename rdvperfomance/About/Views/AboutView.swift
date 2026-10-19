// Tela que exibe informações sobre o aplicativo
import SwiftUI

// View da tela Sobre com card de informações e funcionalidades
struct AboutView: View {

    @Binding var path: [AppRoute]
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F
    }

    init(
        path: Binding<[AppRoute]>,
        onSelectSection: @escaping (StudentMainSection) -> Void = { _ in }
    ) {
        _path = path
        _ = onSelectSection
    }

    private let cardMaxWidth: CGFloat = 360
    private let logoLift: CGFloat = 30
    private let cardLift: CGFloat = 26

    // Constrói a interface da tela Sobre
    var body: some View {
        ZStack {

            AppThemeBackgroundImage()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        Color.clear.frame(height: 8)

                        Image("rdv_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260)
                            .padding(.top, -logoLift)

                        contentCard()
                            .frame(maxWidth: cardMaxWidth)
                            .padding(.top, -38 - cardLift)

                        Color.clear.frame(height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
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
                Text("about.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }

            ToolbarItem(placement: .topBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeLightHeaderColorScheme()
    }

    // Remove a última rota da pilha para voltar
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Retorna o card com informações do app
    private func contentCard() -> some View {
        VStack(spacing: 14) {
            Text("about.headline")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppThemeColor(dark: Color.white, light: LightColors.primaryText))
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureItem("about.feature.create_workouts")
                featureItem("about.feature.track_progress")
                featureItem("about.feature.all_in_one")
            }

            Text("about.description")
                .font(.system(size: 14))
                .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(AppThemeColor(dark: Color.black.opacity(0.68), light: LightColors.cardSurface))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppThemeColor(dark: Theme.Colors.primaryGreen.opacity(0.28), light: LightColors.darkGreenBorder), lineWidth: 1)
        )
        .shadow(
            color: appTheme == .light ? .black.opacity(0.25) : .clear,
            radius: appTheme == .light ? 10 : 0,
            y: appTheme == .light ? 6 : 0
        )
    }

    // Retorna uma linha com ícone de check e texto descritivo
    private func featureItem(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppThemeColor(dark: Color.green, light: LightColors.iconInk))
            Text(text)
                .foregroundStyle(AppThemeColor(dark: Color.white, light: LightColors.primaryText))
        }
    }
}

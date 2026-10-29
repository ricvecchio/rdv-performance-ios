import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case portugueseBrazil = "pt-BR"
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var flagAssetName: String {
        switch self {
        case .portugueseBrazil:
            "flag_br"
        case .english:
            "flag_us"
        case .spanish:
            "flag_es"
        }
    }

    var localizedName: LocalizedStringKey {
        switch self {
        case .portugueseBrazil:
            "settings.language.portuguese_brazil"
        case .english:
            "settings.language.english"
        case .spanish:
            "settings.language.spanish"
        }
    }
}

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var appTheme
    @AppStorage("selectedAppLanguage") private var selectedAppLanguage = AppLanguage.portugueseBrazil.rawValue

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TrainingWeeksView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)      // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F
    }

    private let contentMaxWidth: CGFloat = 380

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
                            languageCard()

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
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
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
                Text("settings.language.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundStyle(Theme.Colors.ink())
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appThemeNavigationBarColorScheme()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageCard() -> some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases) { language in
                languageRow(language)

                if language != .spanish {
                    Divider()
                        .background(Theme.Colors.divider)
                        .padding(.leading, 54)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
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

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            selectedAppLanguage = language.rawValue
        } label: {
            HStack(spacing: 14) {
                Image(language.flagAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                Text(language.localizedName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                Spacer()

                Image(systemName: selectedAppLanguage == language.rawValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        selectedAppLanguage == language.rawValue
                            ? AnyShapeStyle(AppThemeColor(dark: Color.green, light: LightColors.iconInk))
                            : AnyShapeStyle(Theme.Colors.icon(Theme.Colors.ink(0.35)))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

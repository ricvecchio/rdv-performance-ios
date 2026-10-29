import SwiftUI

// Seletor de tema (Escuro / Claro) exibido nos cadastros de Aluno e Professor.
// Mesmo padrão visual da `ThemeSettingsView` e mesma persistência local (`@AppStorage(AppTheme.storageKey)`):
// a escolha é aplicada imediatamente e não é enviada ao Firebase.
struct RegisterThemeSelectionSection: View {
    @AppStorage(AppTheme.storageKey) private var selectedAppTheme = AppTheme.defaultTheme.rawValue
    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores usados pela ThemeSettingsView; Tema Escuro usa os valores originais)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)    // #DDEDDC
        static let iconInk = Color(red: 0x25 / 255, green: 0x48 / 255, blue: 0x2B / 255)        // #25482B
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)    // #171C17
        static let darkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255) // #294A2F
    }

    private var currentTheme: AppTheme {
        AppTheme(storedValue: selectedAppTheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings.theme.description")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.ink(0.6))
                .padding(.horizontal, 6)

            themeCard()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func themeCard() -> some View {
        VStack(spacing: 0) {
            ForEach(AppTheme.allCases) { theme in
                themeRow(theme)

                if theme != AppTheme.allCases.last {
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

    private func themeRow(_ theme: AppTheme) -> some View {
        let isSelected = currentTheme == theme

        return Button {
            selectedAppTheme = theme.rawValue
        } label: {
            HStack(spacing: 14) {
                Image(systemName: theme.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(AppThemeColor(dark: Color.green.opacity(0.85), light: LightColors.iconInk))
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.localizedTitle)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppThemeColor(dark: Color.white.opacity(0.92), light: LightColors.primaryText))

                    Text(theme.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.Colors.ink(0.55))
                }

                Spacer()

                // Indicador visual; o estado é anunciado pelo trait `.isSelected`
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isSelected
                            ? AnyShapeStyle(AppThemeColor(dark: Color.green, light: LightColors.iconInk))
                            : AnyShapeStyle(Theme.Colors.icon(Theme.Colors.ink(0.35)))
                    )
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}


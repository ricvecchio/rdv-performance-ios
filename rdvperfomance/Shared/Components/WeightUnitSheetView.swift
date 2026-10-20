import SwiftUI

// Tema Claro: contorno verde-escuro (#294A2F), mesmo tom do card "Acesso rápido" da TeacherDashboardView.
private let weightUnitDarkGreenBorder = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)

enum WeightUnit: String, CaseIterable {
    case kg
    case lbs

    var title: String {
        let locale = Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
        switch self {
        case .kg: return AppLocalization.string("settings.weight_unit.kilograms", locale: locale)
        case .lbs: return AppLocalization.string("settings.weight_unit.pounds", locale: locale)
        }
    }

    var shortLabel: String {
        switch self {
        case .kg: return "kg"
        case .lbs: return "lbs"
        }
    }
}

struct WeightUnitSheetView: View {

    @Binding var selectedUnitRaw: String
    let onCancel: () -> Void
    let onSave: () -> Void

    @Environment(\.appTheme) private var appTheme

    // Paleta do Tema Claro (mesmos valores da `LightColors` da TeacherDashboardView)
    private enum LightColors {
        static let cardSurface = Color(red: 0xDD / 255, green: 0xED / 255, blue: 0xDC / 255)  // #DDEDDC
        static let primaryText = Color(red: 0x17 / 255, green: 0x1C / 255, blue: 0x17 / 255)  // #171C17
        static let chevron = Color(red: 0x29 / 255, green: 0x4A / 255, blue: 0x2F / 255)      // #294A2F
        static let border = Color(red: 0xC9 / 255, green: 0xDF / 255, blue: 0xC9 / 255)       // #C9DFC9
        static let darkGreenBorder = weightUnitDarkGreenBorder                                  // #294A2F (contorno dos cards e botões)
    }

    private var selectedUnit: WeightUnit {
        WeightUnit(rawValue: selectedUnitRaw) ?? .kg
    }

    var body: some View {
        ZStack {

            Theme.Colors.sheetBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Capsule()
                    .fill(Theme.Colors.ink(0.18))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                Text("settings.weight_unit.title")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink())
                    .padding(.top, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                    VStack(spacing: 0) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Button {
                                selectedUnitRaw = unit.rawValue
                            } label: {
                                HStack(spacing: 12) {
                                    Text(unit.title)
                                        .font(.system(size: 16, weight: .semibold))
                                        // Tema Claro: texto principal #171C17. Tema Escuro: valor original.
                                        .foregroundStyle(AppThemeColor(dark: Theme.Colors.ink(0.92).dark, light: LightColors.primaryText))

                                    Spacer()

                                    // Tema Claro: indicadores em verde militar #294A2F (não selecionado translúcido). Tema Escuro: valores originais.
                                    if unit == selectedUnit {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AppThemeColor(
                                                dark: Theme.Colors.icon(Theme.Colors.accentForeground).dark,
                                                light: LightColors.chevron
                                            ))
                                            .font(.system(size: 18, weight: .semibold))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(AppThemeColor(
                                                dark: Theme.Colors.icon(Theme.Colors.ink(0.25)).dark,
                                                light: LightColors.chevron.opacity(0.45)
                                            ))
                                            .font(.system(size: 18, weight: .regular))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if unit != WeightUnit.allCases.last {
                                Divider()
                                    .background(Theme.Colors.divider)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // Tema Claro: fundo #DDEDDC e borda #C9DFC9 (padrão TeacherDashboardView). Tema Escuro: valores originais.
                    .background(AppThemeColor(dark: Theme.Colors.cardBackground.dark, light: LightColors.cardSurface))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppThemeColor(dark: Theme.Colors.ink(0.08).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
                    )

                    Text("settings.weight_unit.description")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Theme.Colors.ink(0.45))
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }

                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("common.cancel")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.Colors.ink(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.ink(0.10))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppThemeColor(dark: Theme.Colors.ink(0.10).dark, light: LightColors.darkGreenBorder), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onSave) {
                        Text("common.save")
                            .frame(maxWidth: .infinity)
                            // Tema Claro: cores do botão Sair da ProfileView, preservando as medidas de
                            // `primaryGreenActionButton()`. Tema Escuro: estilo original.
                            .modifier(WeightUnitSaveButtonModifier(appTheme: appTheme))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .appThemeNavigationBarColorScheme()
    }
}

// Tema Claro + habilitado: mesmas cores/transparências do botão Sair da ProfileView, preservando
// fonte, padding e arredondamento de `primaryGreenActionButton()`.
// Tema Escuro ou desabilitado: aplica exatamente o `primaryGreenActionButton()` original.
private struct WeightUnitSaveButtonModifier: ViewModifier {
    let appTheme: AppTheme
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        if appTheme == .light && isEnabled {
            content
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.vertical, 14)
                .background(AppThemePalette.lightBar.opacity(0.80))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(weightUnitDarkGreenBorder, lineWidth: 1)
                )
        } else {
            content
                .primaryGreenActionButton()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appTheme == .light ? weightUnitDarkGreenBorder : Color.clear, lineWidth: 1)
                )
        }
    }
}


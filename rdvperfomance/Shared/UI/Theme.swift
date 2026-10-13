// Define as constantes visuais do aplicativo como cores, dimensões e fontes
import SwiftUI

// Agrupa todas as constantes de tema do aplicativo
enum Theme {

    // Cores padronizadas usadas em todo o app
    enum Colors {
        // Cor verde principal do aplicativo
        static let primaryGreen = Color(red: 0.18, green: 0.85, blue: 0.45)

        static let selected = primaryGreen

        // As cores abaixo se adaptam ao tema do app.
        // No Tema Escuro preservam exatamente os valores originais.
        static let unselected = ink(0.7)

        static let headerBackground = AppThemeColor(
            dark: headerBackgroundColor(for: .dark),
            light: headerBackgroundColor(for: .light)
        )
        static let footerBackground = AppThemeColor(
            dark: Color.black.opacity(0.75),
            light: Color.white.opacity(0.95)
        )

        static let divider = AppThemeColor(
            dark: Color.white.opacity(0.2),
            light: Color.black.opacity(0.12)
        )
        static let cardBackground = glass(0.65)

        // Cor de texto principal do Tema Claro (cinza-escuro quase preto)
        static let lightInk = AppThemePalette.lightInk

        // Cor de fundo do cabeçalho por tema (definição única, usada por SwiftUI e UIKit)
        static func headerBackgroundColor(for theme: AppTheme) -> Color {
            switch theme {
            case .dark: Color.black.opacity(0.70)
            case .light: Color.white.opacity(0.94)
            }
        }

        // Verde para TEXTOS e ÍCONES (não usar em fundos/bordas).
        // Escuro: exatamente o verde original. Claro: verde mais escuro para contraste
        // (~6,7:1 sobre branco e ~4,5:1 sobre o tom médio dos tijolos).
        private static let accentForegroundLight = Color(red: 0.0, green: 0.42, blue: 0.19)

        // Substitui `Theme.Colors.primaryGreen` quando usado como cor de texto/ícone
        static let accentForeground = AppThemeColor(
            dark: primaryGreen,
            light: accentForegroundLight
        )

        // Substitui `.green` / `.green.opacity(o)` quando usado como cor de texto/ícone
        static func systemAccentForeground(_ opacity: Double? = nil) -> AppThemeColor {
            AppThemeColor(
                dark: opacity.map { Color.green.opacity($0) } ?? Color.green,
                light: accentForegroundLight.opacity(AppThemePalette.lightOpacity(for: opacity ?? 1))
            )
        }

        // "Tinta": textos, ícones, bordas e preenchimentos sutis.
        // Escuro: Color.white.opacity(o) (valor original). Claro: cinza-escuro com contraste reforçado.
        static func ink(_ opacity: Double = 1) -> AppThemeColor {
            AppThemeColor(
                dark: Color.white.opacity(opacity),
                light: lightInk.opacity(AppThemePalette.lightOpacity(for: opacity))
            )
        }

        // "Vidro": fundos de cards, campos e superfícies.
        // Escuro: Color.black.opacity(o) (valor original). Claro: superfície branca.
        static func glass(_ opacity: Double) -> AppThemeColor {
            AppThemeColor(
                dark: Color.black.opacity(opacity),
                light: Color.white.opacity(AppThemePalette.lightOpacity(for: opacity))
            )
        }
    }

    // Dimensões e espaçamentos padronizados para layout
    enum Layout {
        static let headerHeight: CGFloat = 52
        static let footerHeight: CGFloat = 70

        static let footerItemWidthHomeSobre: CGFloat = 88
        static let footerItemWidthTreinos: CGFloat = 110
        static let footerMiddleSpacerWidth: CGFloat = 88

        static let footerItemWidthHomeSobrePerfil: CGFloat = 92
        static let footerItemWidthTreinosComPerfil: CGFloat = 84

        static let footerVerticalPadding: CGFloat = 10
        static let footerItemIconSize: CGFloat = 20
        static let footerItemTitleSize: CGFloat = 11

        // Tamanhos usados exclusivamente nos rodapés principais (Aluno e Professor)
        static let mainFooterItemIconSize: CGFloat = 23
        static let mainFooterItemTitleSize: CGFloat = 12
    }

    // Fontes padronizadas para diferentes elementos da interface
    enum Fonts {
        // Retorna a fonte para títulos do footer
        static func footerTitle(size: CGFloat = Layout.footerItemTitleSize) -> Font {
            .system(size: size, weight: .medium)
        }

        // Retorna a fonte para ícones do footer
        static func footerIcon(size: CGFloat = Layout.footerItemIconSize) -> Font {
            .system(size: size)
        }

        // Retorna a fonte para títulos do header
        static func headerTitle() -> Font {
            .system(size: 17, weight: .semibold)
        }
    }
}

// Define as constantes visuais do aplicativo como cores, dimensões e fontes
import SwiftUI

// Agrupa todas as constantes de tema do aplicativo
enum Theme {

    // Cores padronizadas usadas em todo o app
    enum Colors {
        // Cor verde principal do aplicativo
        static let primaryGreen = Color(red: 0.18, green: 0.85, blue: 0.45)

        // Item selecionado no rodapé. Escuro: verde original. Claro: verde vibrante sobre o rodapé verde-escuro.
        static let selected = AppThemeColor(
            dark: primaryGreen,
            light: AppThemePalette.lightSelected,
            followsBarColorScheme: false
        )

        // As cores abaixo se adaptam ao tema do app.
        // No Tema Escuro preservam exatamente os valores originais.
        static let unselected = ink(0.7)

        static let headerBackground = AppThemeColor(
            dark: headerBackgroundColor(for: .dark),
            light: headerBackgroundColor(for: .light),
            followsBarColorScheme: false
        )
        static let footerBackground = AppThemeColor(
            dark: Color.black.opacity(0.75),
            light: AppThemePalette.lightBar,
            followsBarColorScheme: false
        )

        // Fundo de tela cheia de sheets/modais (antes usavam `headerBackground`).
        // Escuro: idêntico ao cabeçalho original. Claro: mantém a superfície clara.
        static let sheetBackground = AppThemeColor(
            dark: headerBackgroundColor(for: .dark),
            light: Color.white.opacity(0.94),
            followsBarColorScheme: false
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
            case .light: AppThemePalette.lightBar
            }
        }

        // Verde para TEXTOS e ÍCONES (não usar em fundos/bordas).
        // Escuro: exatamente o verde original. Claro: verde forte (#008C43).
        private static let accentForegroundLight = AppThemePalette.lightAccent

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
        // Escuro: Color.black.opacity(o) (valor original). Claro: verde pastel (#D5F1DC),
        // preservando as diferenças de opacidade entre os componentes.
        static func glass(_ opacity: Double) -> AppThemeColor {
            AppThemeColor(
                dark: Color.black.opacity(opacity),
                light: AppThemePalette.lightSurface.opacity(AppThemePalette.lightOpacity(for: opacity))
            )
        }

        // Borda fina dos cards. Escuro: `primaryGreen.opacity(0.28)` (valor original). Claro: #ABDABC.
        static let cardBorder = AppThemeColor(
            dark: primaryGreen.opacity(0.28),
            light: AppThemePalette.lightCardBorder
        )

        // Superfície de fundo dos ícones dos cards.
        // Escuro: exatamente a cor original recebida. Claro: verde mais destacado (#AAF0C5).
        static func iconSurface(_ dark: Color) -> AppThemeColor {
            AppThemeColor(
                dark: dark,
                light: AppThemePalette.lightIconSurface
            )
        }

        // Setas de navegação (chevron) dos cards.
        // Escuro: Color.white.opacity(o) (valor original, igual a `ink(o)`). Claro: verde militar das barras.
        static func chevron(_ opacity: Double) -> AppThemeColor {
            icon(Color.white.opacity(opacity))
        }

        // Ícones internos das telas (conteúdo; não usar no cabeçalho/rodapé).
        // Escuro: exatamente a cor original recebida. Claro: verde militar sólido das barras.
        static func icon(_ dark: Color) -> AppThemeColor {
            AppThemeColor(
                dark: dark,
                light: AppThemePalette.lightBar
            )
        }

        // Mesmo comportamento de `icon(_:)` para ícones que já usavam uma cor dinâmica:
        // preserva o valor original do Tema Escuro.
        static func icon(_ original: AppThemeColor) -> AppThemeColor {
            icon(original.dark)
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

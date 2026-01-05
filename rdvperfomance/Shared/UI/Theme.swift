// Theme.swift — Constantes visuais: cores, layout e fontes do app
import SwiftUI

enum Theme {

    enum Colors {
        // Cor primária verde do app
        static let primaryGreen = Color(red: 0.18, green: 0.85, blue: 0.45)

        static let selected = primaryGreen
        static let unselected = Color.white.opacity(0.7)

        static let headerBackground = Color.black.opacity(0.70)
        static let footerBackground = Color.black.opacity(0.75)

        static let divider = Color.white.opacity(0.2)
        static let cardBackground = Color.black.opacity(0.65)
    }

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
    }

    enum Fonts {
        static func footerTitle() -> Font {
            .system(size: Layout.footerItemTitleSize, weight: .medium)
        }

        static func footerIcon() -> Font {
            .system(size: Layout.footerItemIconSize)
        }

        static func headerTitle() -> Font {
            .system(size: 17, weight: .semibold)
        }
    }
}

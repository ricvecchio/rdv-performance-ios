import SwiftUI

// MARK: - Theme
// Centraliza constantes visuais para manter consistência no app.
enum Theme {

    enum Colors {

        /// ✅ Verde oficial do app (mais forte e consistente que o `.green` padrão do iOS)
        /// Ajuste fino: se quiser mais forte, aumente um pouco o green (0.84 -> 0.88)
        /// ou reduza o blue (0.44 -> 0.40).
        static let primaryGreen = Color(red: 0.18, green: 0.85, blue: 0.45)

        /// ✅ Mantém compatibilidade com o app (qualquer lugar que usa `selected` continua funcionando)
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

        // ✅ Rodapé com 3 itens (Home/Sobre/Perfil)
        static let footerItemWidthHomeSobrePerfil: CGFloat = 92

        // ✅ NOVO: Rodapé com 4 itens (Home/Treinos/Sobre/Perfil)
        // Ajuste fino: se ainda ficar apertado no seu device, pode reduzir p/ 78–82.
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


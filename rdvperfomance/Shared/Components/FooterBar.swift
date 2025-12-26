import SwiftUI

// MARK: - FooterBar
// Componente reutilizável para o rodapé do app.
// Cobre dois cenários do teu projeto:
//
// 1) Rodapé simples: Home | (espaço) | Sobre
//    - usado em HomeView e AboutView (tela Sobre)
//
// 2) Rodapé de Treinos: Home | Treinos (custom icon) | Sobre
//    - usado em TreinosView
//
// O componente recebe o `path` para navegar via AppRoute, igual ao teu padrão atual.
struct FooterBar: View {

    // MARK: - Tipos de Rodapé
    enum Kind {
        /// Home | (espaço) | Sobre
        case homeSobre(
            isHomeSelected: Bool,
            isSobreSelected: Bool
        )

        /// Home | Treinos (custom icon) | Sobre
        case treinos(
            treinoTitle: String,
            treinoIcon: AnyView,     // permite receber ícone custom como view
            isHomeSelected: Bool,
            isTreinoSelected: Bool,
            isSobreSelected: Bool
        )
    }

    // MARK: - Inputs
    @Binding var path: [AppRoute]
    let kind: Kind

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Theme.Colors.divider)

            switch kind {
            case .homeSobre(let isHomeSelected, let isSobreSelected):
                homeSobreRow(isHomeSelected: isHomeSelected, isSobreSelected: isSobreSelected)

            case .treinos(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, let isSobreSelected):
                treinosRow(
                    treinoTitle: treinoTitle,
                    treinoIcon: treinoIcon,
                    isHomeSelected: isHomeSelected,
                    isTreinoSelected: isTreinoSelected,
                    isSobreSelected: isSobreSelected
                )
            }
        }
        .padding(.vertical, Theme.Layout.footerVerticalPadding)
    }

    // MARK: - Rows

    private func homeSobreRow(isHomeSelected: Bool, isSobreSelected: Bool) -> some View {
        HStack(spacing: 28) {

            // Home
            Button { goHome() } label: {
                FooterItem(
                    icon: .system("house"),
                    title: "Home",
                    isSelected: isHomeSelected,
                    width: Theme.Layout.footerItemWidthHomeSobre
                )
            }
            .buttonStyle(.plain)

            // Spacer central (para manter o visual igual ao teu código atual)
            Color.clear
                .frame(width: Theme.Layout.footerMiddleSpacerWidth, height: 1)

            // Sobre
            Button { goSobre(avoidDuplicate: true) } label: {
                FooterItem(
                    icon: .system("bubble.left"),
                    title: "Sobre",
                    isSelected: isSobreSelected,
                    width: Theme.Layout.footerItemWidthHomeSobre
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func treinosRow(
        treinoTitle: String,
        treinoIcon: AnyView,
        isHomeSelected: Bool,
        isTreinoSelected: Bool,
        isSobreSelected: Bool
    ) -> some View {

        HStack(spacing: 28) {

            // Home
            Button { goHome() } label: {
                FooterItem(
                    icon: .system("house"),
                    title: "Home",
                    isSelected: isHomeSelected,
                    width: Theme.Layout.footerItemWidthTreinos
                )
            }
            .buttonStyle(.plain)

            // Treinos (custom icon)
            FooterItem(
                icon: .custom(treinoIcon),
                title: treinoTitle,
                isSelected: isTreinoSelected,
                width: Theme.Layout.footerItemWidthTreinos
            )

            // Sobre
            Button { goSobre(avoidDuplicate: false) } label: {
                FooterItem(
                    icon: .system("bubble.left"),
                    title: "Sobre",
                    isSelected: isSobreSelected,
                    width: Theme.Layout.footerItemWidthTreinos
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Navigation helpers

    /// Volta para Home limpando a pilha (padrão consistente do teu projeto)
    private func goHome() {
        path.removeAll()
        path.append(.home)
    }

    /// Navega para Sobre.
    /// `avoidDuplicate=true` evita empilhar várias vezes a mesma tela, como você já faz no Sobre.
    private func goSobre(avoidDuplicate: Bool) {
        if avoidDuplicate {
            if path.last != .sobre { path.append(.sobre) }
        } else {
            path.append(.sobre)
        }
    }
}

// MARK: - FooterItem (internal)
// Item padrão do rodapé: ícone + texto.
// Aceita SF Symbol OU uma View custom (caso do TreinoTipo).
private struct FooterItem: View {

    enum Icon {
        case system(String)
        case custom(AnyView)
    }

    let icon: Icon
    let title: String
    let isSelected: Bool
    let width: CGFloat

    var body: some View {
        VStack(spacing: 6) {

            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .font(Theme.Fonts.footerIcon())

            case .custom(let view):
                view
            }

            Text(title)
                .font(Theme.Fonts.footerTitle())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(isSelected ? Theme.Colors.selected : Theme.Colors.unselected)
        .frame(width: width)
    }
}


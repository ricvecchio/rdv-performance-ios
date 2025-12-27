import SwiftUI

// MARK: - FooterBar
// Rodapé reutilizável. Importante:
// ✅ NÃO fixa altura aqui dentro (quem define a altura é a tela).
// ✅ Linha separadora fica colada no topo do rodapé, sempre.
struct FooterBar: View {

    enum Kind {
        case homeSobre(isHomeSelected: Bool, isSobreSelected: Bool)

        case homeSobrePerfil(
            isHomeSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
        )

        case treinos(
            treinoTitle: String,
            treinoIcon: AnyView,
            isHomeSelected: Bool,
            isTreinoSelected: Bool,
            isSobreSelected: Bool
        )
    }

    @Binding var path: [AppRoute]
    let kind: Kind

    var body: some View {
        VStack(spacing: 0) {

            // ✅ Separador fixo colado no topo do rodapé
            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
                .frame(maxWidth: .infinity)

            contentRow()
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        // ✅ Preenche o espaço do container e ancora no topo
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.footerBackground)
    }

    @ViewBuilder
    private func contentRow() -> some View {
        switch kind {

        case .homeSobre(let isHomeSelected, let isSobreSelected):
            HStack(spacing: 28) {
                Button { goHome() } label: {
                    FooterItem(
                        icon: .system("house"),
                        title: "Home",
                        isSelected: isHomeSelected,
                        width: Theme.Layout.footerItemWidthHomeSobre
                    )
                }
                .buttonStyle(.plain)

                Color.clear
                    .frame(width: Theme.Layout.footerMiddleSpacerWidth, height: 1)

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

        case .homeSobrePerfil(let isHomeSelected, let isSobreSelected, let isPerfilSelected):
            HStack(spacing: 26) {
                Button { goHome() } label: {
                    FooterItem(
                        icon: .system("house"),
                        title: "Home",
                        isSelected: isHomeSelected,
                        width: Theme.Layout.footerItemWidthHomeSobrePerfil
                    )
                }
                .buttonStyle(.plain)

                Button { goSobre(avoidDuplicate: true) } label: {
                    FooterItem(
                        icon: .system("bubble.left"),
                        title: "Sobre",
                        isSelected: isSobreSelected,
                        width: Theme.Layout.footerItemWidthHomeSobrePerfil
                    )
                }
                .buttonStyle(.plain)

                Button { goPerfil(avoidDuplicate: true) } label: {
                    FooterItem(
                        icon: .system("person"),
                        title: "Perfil",
                        isSelected: isPerfilSelected,
                        width: Theme.Layout.footerItemWidthHomeSobrePerfil
                    )
                }
                .buttonStyle(.plain)
            }

        case .treinos(let treinoTitle, let treinoIcon, let isHomeSelected, let isTreinoSelected, let isSobreSelected):
            HStack(spacing: 28) {
                Button { goHome() } label: {
                    FooterItem(
                        icon: .system("house"),
                        title: "Home",
                        isSelected: isHomeSelected,
                        width: Theme.Layout.footerItemWidthTreinos
                    )
                }
                .buttonStyle(.plain)

                FooterItem(
                    icon: .custom(treinoIcon),
                    title: treinoTitle,
                    isSelected: isTreinoSelected,
                    width: Theme.Layout.footerItemWidthTreinos
                )

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
    }

    // MARK: - Navigation helpers
    private func goHome() {
        path.removeAll()
        path.append(.home)
    }

    private func goSobre(avoidDuplicate: Bool) {
        if avoidDuplicate {
            if path.last != .sobre { path.append(.sobre) }
        } else {
            path.append(.sobre)
        }
    }

    private func goPerfil(avoidDuplicate: Bool) {
        if avoidDuplicate {
            if path.last != .perfil { path.append(.perfil) }
        } else {
            path.append(.perfil)
        }
    }
}

// MARK: - FooterItem (internal)
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


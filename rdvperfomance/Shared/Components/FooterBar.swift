import SwiftUI

// MARK: - FooterBar
// Rodapé reutilizável.
// ✅ Linha separadora colada no topo do rodapé.
// ✅ Navegação com padrão "push/pop" para Home/Sobre/Perfil.
// ✅ NOVO: suporte a 4 itens (Home | Treinos | Sobre | Perfil) para CrossfitMenuView.
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

        // ✅ NOVO: Treinos com Perfil (4 itens)
        case treinosComPerfil(
            treinoTitle: String,
            treinoIcon: AnyView,
            isHomeSelected: Bool,
            isTreinoSelected: Bool,
            isSobreSelected: Bool,
            isPerfilSelected: Bool
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

                Button { goSobre() } label: {
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

                Button { goSobre() } label: {
                    FooterItem(
                        icon: .system("bubble.left"),
                        title: "Sobre",
                        isSelected: isSobreSelected,
                        width: Theme.Layout.footerItemWidthHomeSobrePerfil
                    )
                }
                .buttonStyle(.plain)

                Button { goPerfil() } label: {
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

                Button { goSobre() } label: {
                    FooterItem(
                        icon: .system("bubble.left"),
                        title: "Sobre",
                        isSelected: isSobreSelected,
                        width: Theme.Layout.footerItemWidthTreinos
                    )
                }
                .buttonStyle(.plain)
            }

        case .treinosComPerfil(
            let treinoTitle,
            let treinoIcon,
            let isHomeSelected,
            let isTreinoSelected,
            let isSobreSelected,
            let isPerfilSelected
        ):
            // ✅ 4 itens: Home | Treinos | Sobre | Perfil
            HStack(spacing: 16) {
                Button { goHome() } label: {
                    FooterItem(
                        icon: .system("house"),
                        title: "Home",
                        isSelected: isHomeSelected,
                        width: Theme.Layout.footerItemWidthTreinosComPerfil
                    )
                }
                .buttonStyle(.plain)

                FooterItem(
                    icon: .custom(treinoIcon),
                    title: treinoTitle,
                    isSelected: isTreinoSelected,
                    width: Theme.Layout.footerItemWidthTreinosComPerfil
                )

                Button { goSobre() } label: {
                    FooterItem(
                        icon: .system("bubble.left"),
                        title: "Sobre",
                        isSelected: isSobreSelected,
                        width: Theme.Layout.footerItemWidthTreinosComPerfil
                    )
                }
                .buttonStyle(.plain)

                Button { goPerfil() } label: {
                    FooterItem(
                        icon: .system("person"),
                        title: "Perfil",
                        isSelected: isPerfilSelected,
                        width: Theme.Layout.footerItemWidthTreinosComPerfil
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Navegação (push/pop)

    /// Pilha principal canônica:
    /// [.home] -> [.home, .sobre] -> [.home, .sobre, .perfil]
    private func canonicalStack(for destination: AppRoute) -> [AppRoute] {
        switch destination {
        case .home:
            return [.home]
        case .sobre:
            return [.home, .sobre]
        case .perfil:
            return [.home, .sobre, .perfil]
        default:
            return [.home]
        }
    }

    private func currentMainRoute() -> AppRoute? {
        for r in path.reversed() {
            if r == .home || r == .sobre || r == .perfil {
                return r
            }
        }
        return nil
    }

    private func goHome() {
        withAnimation {
            if path.last == .sobre || path.last == .perfil {
                while path.last != .home && !path.isEmpty {
                    path.removeLast()
                }
                if path.last != .home { path = canonicalStack(for: .home) }
            } else {
                path = canonicalStack(for: .home)
            }
        }
    }

    private func goSobre() {
        withAnimation {
            let current = currentMainRoute()

            switch current {
            case .perfil:
                if path.last == .perfil {
                    path.removeLast()
                } else {
                    path = canonicalStack(for: .sobre)
                }

            case .home:
                if path.last != .sobre {
                    path = canonicalStack(for: .sobre)
                }

            case .sobre:
                break

            default:
                path = canonicalStack(for: .sobre)
            }
        }
    }

    private func goPerfil() {
        withAnimation {
            let current = currentMainRoute()

            switch current {
            case .sobre:
                if path.last != .perfil {
                    path.append(.perfil)
                }

            case .home:
                path = canonicalStack(for: .perfil)

            case .perfil:
                break

            default:
                path = canonicalStack(for: .perfil)
            }
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


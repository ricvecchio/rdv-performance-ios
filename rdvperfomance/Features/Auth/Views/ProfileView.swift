import SwiftUI

// MARK: - ProfileView
// Tela de perfil (pós-login). Exibe informações e opções do usuário.
struct ProfileView: View {

    @Binding var path: [AppRoute]

    // largura máxima do “miolo” (conteúdo central)
    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        ZStack {

            // FUNDO
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Estrutura fixa: SEPARADOR / CONTEÚDO / FOOTER
            VStack(spacing: 0) {

                // ✅ Separador entre NavigationBar e corpo
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                // ✅ CONTEÚDO (scroll apenas no corpo)
                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(spacing: 16) {
                            profileCard()
                            optionsCard()
                            logoutButton()
                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

                // ✅ FOOTER FIXO
                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: true
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)

        // ✅ Toolbar ativa (NavigationBar real)
        .toolbar {

            // Título central
            ToolbarItem(placement: .principal) {
                Text("Perfil")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            // Engrenagem
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(.configuracoes)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Card superior (dados do perfil)
    private func profileCard() -> some View {
        VStack(spacing: 10) {

            ZStack(alignment: .bottomTrailing) {
                Image("rdv_eu")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 92, height: 92)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)

                Circle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "camera.aperture")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.95))
                    )
                    .offset(x: 6, y: 6)
            }

            Text("ID 32457")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Text("Ricardo Del Vecchio")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)

            Text("CROSSFIT MURALHA")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Card de opções
    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            optionRow(icon: "wallet.pass", title: "Carteira", trailing: .chevron)
            divider()

            optionRow(icon: "doc.text", title: "Planos", trailing: .badge("Ativo"))
            divider()

            optionRow(icon: "arrow.clockwise", title: "Reposições", trailing: .text("Ver mais"))
            divider()

            optionRow(icon: "calendar.badge.checkmark", title: "Sessões", trailing: .text("Ver mais"))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 56)
    }

    private enum Trailing {
        case chevron
        case text(String)
        case badge(String)
    }

    private func optionRow(icon: String, title: String, trailing: Trailing) -> some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.85))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.95))

            Spacer()

            switch trailing {
            case .chevron:
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.35))

            case .text(let value):
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green.opacity(0.85))

            case .badge(let value):
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Logout
    private func logoutButton() -> some View {
        Button {
            path.removeAll()
        } label: {
            Text("Sair")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Color.green.opacity(0.75)))
        }
        .buttonStyle(.plain)
    }
}


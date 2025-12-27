import SwiftUI

// MARK: - ProfileView
// Tela de perfil (pós-login). Exibe informações e opções do usuário.
struct ProfileView: View {

    @Binding var path: [AppRoute]

    // largura máxima do “miolo” (conteúdo central)
    private let contentMaxWidth: CGFloat = 380

    // Exemplo de check-ins da semana
    private let checkinsRealizados: Int = 2
    private let checkinsMetaSemana: Int = 6

    var body: some View {
        ZStack {

            // FUNDO
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Separador entre NavigationBar e corpo
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                // Conteúdo
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

                // Footer
                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: true
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {

            ToolbarItem(placement: .principal) {
                Text("Perfil")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    path.append(.configuracoes)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.green) // mantém coerência visual
                }
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Card superior
    private func profileCard() -> some View {
        VStack(spacing: 10) {

            Image("rdv_eu")
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

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
    }

    // MARK: - Card de opções
    private func optionsCard() -> some View {
        VStack(spacing: 0) {

            optionRow(icon: "ruler", title: "Trocar unidade", trailing: .chevron)
            divider()

            optionRow(icon: "crown.fill", title: "Planos", trailing: .badge("Ativo"))
            divider()

            optionRow(
                icon: "checkmark.seal.fill",
                title: "Check-ins na semana",
                trailing: .text("\(checkinsRealizados)/\(checkinsMetaSemana)")
            )
            divider()

            optionRow(icon: "trophy.fill", title: "Personal Records", trailing: .text("Ver mais"))
        }
        .padding(.vertical, 8)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
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

    // ✅ ÍCONES AGORA VERDES (PADRÃO SETTINGSVIEW)
    private func optionRow(icon: String, title: String, trailing: Trailing) -> some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85)) // 🔥 CORRIGIDO
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
                .font(.system(size: 17, weight: .medium)) // mais leve que semibold
                .foregroundColor(.white.opacity(0.9))     // melhor contraste no verde suave
                .frame(maxWidth: .infinity)
                .frame(height: 52)                        // um pouco menor
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.28))  // ✅ mais suave
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1) // borda sutil
                        )
                )
                .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6) // sombra bem leve
        }
        .buttonStyle(.plain)
    }

}


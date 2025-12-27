import SwiftUI

// MARK: - SettingsView
// Tela de configurações acessada pelo Perfil.
struct SettingsView: View {

    @Binding var path: [AppRoute]

    private let contentMaxWidth: CGFloat = 380

    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ✅ Separador entre NavigationBar e corpo
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                // Corpo
                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 16) {

                            settingsCardTop()

                            Text("SEGURANÇA")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(.horizontal, 6)

                            securityCard()
                            extraCard()

                            feedbackRow()
                                .padding(.top, 4)

                            Color.clear.frame(height: 16)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

                // Rodapé
                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: false,
                        isSobreSelected: false,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)

        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("Configurações")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - Cards (inalterados)

    private func settingsCardTop() -> some View {
        VStack(spacing: 0) {
            row(icon: "person.fill", title: "Editar Perfil")
            divider()
            row(icon: "bell.fill", title: "Alterar Senha")
            divider()
            row(icon: "slider.horizontal.3", title: "Excluir Conta")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func securityCard() -> some View {
        VStack(spacing: 0) {
            row(icon: "checkmark.shield.fill", title: "Alterar Senha")
            divider()
            row(icon: "globe", title: "Idiomas")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func extraCard() -> some View {
        VStack(spacing: 0) {
            row(icon: "questionmark.circle.fill", title: "Ajuda")
            divider()
            row(icon: "info.circle.fill", title: "Sobre")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func feedbackRow() -> some View {
        row(icon: "text.bubble.fill", title: "Feedback")
    }

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 54)
    }

    private func row(icon: String, title: String) -> some View {
        HStack(spacing: 14) {

            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.green.opacity(0.85))
                .frame(width: 28)

            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.92))

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }
}


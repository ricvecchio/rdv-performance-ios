import SwiftUI

// MARK: - SettingsView
// Tela de configurações acessada pelo Perfil.
struct SettingsView: View {

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

                            // ===== CONTA =====
                            sectionTitle("CONTA")
                            accountCard()

                            // ===== PREFERÊNCIAS =====
                            sectionTitle("PREFERÊNCIAS")
                            preferencesCard()

                            // ===== SUPORTE & LEGAL =====
                            sectionTitle("SUPORTE & LEGAL")
                            supportLegalCard()

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

    // MARK: - Navegação

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - Seções

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 6)
    }

    // MARK: - Cards (organizados conforme solicitado)

    private func accountCard() -> some View {
        card {
            cardRow(icon: "person.crop.circle", title: "Editar Perfil") {
                // ✅ Navega para a nova tela de edição de perfil
                path.append(.editarPerfil)
            }
            divider()
            cardRow(icon: "key.fill", title: "Alterar Senha") {
                // TODO: navegar para fluxo de alteração de senha
            }
            divider()
            cardRow(icon: "trash.fill", title: "Excluir Conta") {
                // TODO: abrir confirmação e executar exclusão
            }
        }
    }

    private func preferencesCard() -> some View {
        card {
            cardRow(icon: "ruler.fill", title: "Unidade de Medida") {
                // TODO: navegar para tela de unidade de medida
            }
        }
    }

    private func supportLegalCard() -> some View {
        card {
            cardRow(icon: "questionmark.circle.fill", title: "Central de Ajuda") {
                path.append(.infoLegal(.helpCenter))
            }
            divider()
            cardRow(icon: "hand.raised.fill", title: "Políticas de Privacidade") {
                path.append(.infoLegal(.privacyPolicy))
            }
            divider()
            cardRow(icon: "doc.text.fill", title: "Termos de Uso") {
                path.append(.infoLegal(.termsOfUse))
            }
        }
    }

    // MARK: - Componentes base

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    private func divider() -> some View {
        Divider()
            .background(Theme.Colors.divider)
            .padding(.leading, 54)
    }

    /// Linha usada dentro dos cards (sem fundo próprio, para não “duplicar card”).
    private func cardRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


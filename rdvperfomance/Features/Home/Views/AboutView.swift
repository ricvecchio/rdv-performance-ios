import SwiftUI

// MARK: - TELA SOBRE (AboutView)
// Tela institucional do app (Sobre).
// Exibe informações do aplicativo e mantém header/footer fixos.
struct AboutView: View {

    // ✅ Navegação controlada via NavigationStack
    @Binding var path: [AppRoute]

    // MARK: - Layout
    private let cardMaxWidth: CGFloat = 360

    // Ajustes finos (subir logo e card)
    private let logoLift: CGFloat = 30
    private let cardLift: CGFloat = 26

    var body: some View {
        ZStack {

            // 🔹 FUNDO
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // 🔹 ESTRUTURA FIXA: HEADER / CONTEÚDO / FOOTER
            VStack(spacing: 0) {

                // ✅ HEADER FIXO
                headerBar()
                    .frame(height: Theme.Layout.headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.headerBackground)

                // 🔹 CONTEÚDO
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        Color.clear
                            .frame(height: 8)

                        // LOGO (subido)
                        Image("rdv_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260)
                            .padding(.top, -logoLift)

                        // CARD (subido)
                        contentCard()
                            .frame(maxWidth: cardMaxWidth)
                            .padding(.top, -38 - cardLift)

                        Color.clear
                            .frame(height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }

                // ✅ FOOTER FIXO (IGUAL AO DA HOME)
                FooterBar(
                    path: $path,
                    kind: .homeSobre(isHomeSelected: false, isSobreSelected: true)
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - HEADER BAR (com "< Voltar" verde)
    private func headerBar() -> some View {
        HStack {

            // Botão voltar: remove a última rota com segurança
            Button {
                pop()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))

                    Text("Voltar")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.green)
                .padding(.leading, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Título central do header
            Text("Sobre")
                .font(Theme.Fonts.headerTitle())
                .foregroundColor(.white)

            Spacer()

            // Placeholder para manter título centralizado
            Color.clear
                .frame(width: 80, height: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 6)
    }

    // Remove a última rota da pilha (evita crash se estiver vazia)
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // MARK: - CARD (conteúdo da tela Sobre)
    private func contentCard() -> some View {
        VStack(spacing: 14) {

            Text("GERENCIE SEUS ALUNOS E PERSONALIZE TREINOS COM FACILIDADE")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                featureItem("Crie treinos personalizados para seus alunos")
                featureItem("Acompanhe a evolução de cada aluno baseado no programa selecionado")
                featureItem("Tudo em um só lugar com interface intuitiva e prática")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Sua ferramenta para otimizar o acompanhamento dos seus alunos e seus treinos!")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
    }

    // Item com checkmark para listar funcionalidades
    private func featureItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


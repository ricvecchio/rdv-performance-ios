import SwiftUI

// MARK: - TELA SOBRE (AboutView)
struct AboutView: View {

    @Binding var path: [AppRoute]

    // MARK: - Layout
    private let cardMaxWidth: CGFloat = 360
    private let logoLift: CGFloat = 30
    private let cardLift: CGFloat = 26

    var body: some View {
        ZStack {

            // FUNDO
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // ESTRUTURA: CONTEÚDO / FOOTER
            VStack(spacing: 0) {

                // ✅ Separador entre NavigationBar e corpo (mesmo padrão das outras telas)
                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                // CONTEÚDO
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

                // FOOTER FIXO
                FooterBar(
                    path: $path,
                    kind: .homeSobrePerfil(
                        isHomeSelected: false,
                        isSobreSelected: true,
                        isPerfilSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)

        // ✅ TOOLBAR PADRÃO (igual Home/Treinos)
        .toolbar(content: {

            // Voltar verde
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            // Título central
            ToolbarItem(placement: .principal) {
                Text("Sobre")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            // Avatar no canto direito (mesmo padrão da HomeView)
            ToolbarItem(placement: .navigationBarTrailing) {
                MiniProfileHeader(imageName: "rdv_eu", size: 38)
                    .onTapGesture {
                        // Se quiser navegar ao tocar:
                        // path.append(.perfil)
                    }
            }
        })
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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


import SwiftUI

// MARK: - TELA DE TREINOS (genérica)
// Tela reutilizável para exibir conteúdo de treinos baseado no TreinoTipo.
// Mostra: header com título, imagem principal com overlay, e rodapé com ícone customizado do tipo.
struct TreinosView: View {

    // Binding para controlar navegação
    @Binding var path: [AppRoute]

    // Tipo de treino atual (Crossfit, Academia ou Em Casa)
    let tipo: TreinoTipo

    var body: some View {
        ZStack {

            // Fundo fixo da tela
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header com título do tipo de treino e botão voltar
                HeaderBar {
                    headerBar(title: tipo.titulo)
                }

                // Área central com imagem + título sobreposto
                GeometryReader { proxy in
                    VStack {
                        Spacer(minLength: 12)

                        ZStack(alignment: .bottom) {

                            // Imagem principal (conforme tipo selecionado)
                            Image(tipo.imagemCorpo)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: min(proxy.size.width - 32, 520))
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 6)

                            // Texto sobreposto na parte inferior da imagem
                            Text(tipo.tituloOverlayImagem)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.95), radius: 8, x: 0, y: 3)
                                .padding(.bottom, 22)
                                .padding(.horizontal, 22)
                                .frame(maxWidth: min(proxy.size.width - 32, 520), alignment: .center)
                        }

                        Spacer(minLength: 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                }

                // Rodapé com Home | Treinos (custom) | Sobre
                FooterBar(
                    path: $path,
                    kind: .treinos(
                        treinoTitle: tipo.titulo,
                        treinoIcon: AnyView(tipo.iconeRodapeTreinos),
                        isHomeSelected: false,
                        isTreinoSelected: true,
                        isSobreSelected: false
                    )
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        // Remove barra padrão do NavigationStack
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - HEADER BAR
    // Header custom com botão voltar verde e título centralizado.
    private func headerBar(title: String) -> some View {
        HStack {

            Button { pop() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                    Text("Voltar")
                }
                .foregroundColor(.green)
                .padding(.leading, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            // Título do header (depende do tipo)
            Text(title)
                .font(Theme.Fonts.headerTitle())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            // Placeholder para manter o título centralizado
            Color.clear.frame(width: 80, height: 1)
        }
        .padding(.top, 6)
    }

    // Volta uma tela removendo a última rota da pilha
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}


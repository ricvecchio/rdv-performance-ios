import SwiftUI

// MARK: - HOME VIEW (tela com 3 opções)
// Tela inicial após o login.
// Exibe três opções de programa (Crossfit, Academia, Treinos em casa).
// Ao tocar em uma opção, salva o último treino selecionado e navega para a tela de treinos.
struct HomeView: View {

    // Binding para controlar a navegação do app via NavigationStack
    @Binding var path: [AppRoute]

    // Salva em cache o último treino escolhido (persistido no aparelho)
    // Útil caso você queira abrir direto no último treino no futuro.
    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    var body: some View {
        ZStack {

            // Fundo da tela
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header fixo com título e botão voltar
                headerView()
                    .frame(height: Theme.Layout.headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.headerBackground)

                // Divide a área central em 3 “faixas” de altura igual
                GeometryReader { proxy in
                    let tileHeight = proxy.size.height / 3

                    VStack(spacing: 0) {

                        // Opção Crossfit
                        programaTile(
                            title: "Crossfit",
                            imageName: "rdv_programa_crossfit_horizontal",
                            height: tileHeight,
                            imageTitle: "Crossfit",
                            tipo: .crossfit
                        )

                        // Opção Academia
                        programaTile(
                            title: "Academia",
                            imageName: "rdv_programa_academia_horizontal",
                            height: tileHeight,
                            imageTitle: "Academia",
                            tipo: .academia
                        )

                        // Opção Treinos em casa
                        programaTile(
                            title: "Treinos em casa",
                            imageName: "rdv_programa_treinos_em_casa_horizontal",
                            height: tileHeight,
                            imageTitle: "Treinos em casa",
                            tipo: .emCasa
                        )
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }

                // Rodapé somente com Home e Sobre (sem Treinos)
                FooterBar(
                    path: $path,
                    kind: .homeSobre(isHomeSelected: true, isSobreSelected: false)
                )
                .frame(height: Theme.Layout.footerHeight)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        // Remove o back button padrão do NavigationStack
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - TILE (botão de programa)
    // Cria um “bloco clicável” com imagem + textos.
    // Ao tocar, salva o treino selecionado e navega para a tela TreinosView.
    private func programaTile(
        title: String,
        imageName: String,
        height: CGFloat,
        imageTitle: String,
        tipo: TreinoTipo
    ) -> some View {

        Button {
            // Salva o último treino escolhido e navega para a tela de treinos
            ultimoTreinoSelecionado = tipo.rawValue
            path.append(.treinos(tipo))
        } label: {

            ZStack {
                GeometryReader { geo in
                    let w = geo.size.width

                    ZStack {
                        // Base escura para garantir contraste
                        Color.black

                        // Imagem do programa
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: w - 16)
                            .frame(maxHeight: .infinity)

                            // Máscara lateral para criar “fade” nas bordas
                            .overlay(
                                Rectangle()
                                    .fill(Color.black.opacity(0.7))
                                    .mask(
                                        HStack(spacing: 0) {
                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                            .frame(width: 20)

                                            Spacer()

                                            LinearGradient(
                                                gradient: Gradient(colors: [.black, .clear]),
                                                startPoint: .trailing,
                                                endPoint: .leading
                                            )
                                            .frame(width: 20)
                                        }
                                    )
                            )
                    }
                    .frame(width: w, height: height)
                    .clipped()

                    // Texto grande sobre a imagem (overlay principal)
                    .overlay(alignment: .bottomLeading) {
                        Text(imageTitle)
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 3)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .padding(.leading, 200)
                            .padding(.trailing, 24)
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Gradiente inferior para melhorar legibilidade do texto de baixo
                    .overlay {
                        LinearGradient(
                            colors: [
                                .black.opacity(0.70),
                                .black.opacity(0.15),
                                .clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    }

                    // Texto pequeno inferior (nome do programa)
                    .overlay(alignment: .bottomLeading) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.leading, 24)
                            .padding(.trailing, 24)
                            .padding(.bottom, 12)
                    }
                }
                .frame(height: height)

                // Pequenos gradientes superior/inferior para “acabamento”
                VStack {
                    LinearGradient(
                        colors: [.black.opacity(0.15), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 4)

                    Spacer()

                    LinearGradient(
                        colors: [.black.opacity(0.15), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 4)
                }
                .frame(height: height)
                .allowsHitTesting(false)
            }
            // Borda suave para dar destaque ao tile
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        // Sombra/contraste de fundo do botão
        .background(
            Color.black.opacity(0.3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .frame(height: height)
    }

    // MARK: - HEADER
    // Header simples com título no centro e botão de voltar à esquerda.
    private func headerView() -> some View {
        ZStack {
            Text("Home")
                .font(Theme.Fonts.headerTitle())
                .foregroundColor(.white)

            HStack {
                Button {
                    // Volta uma rota na pilha, caso exista
                    if !path.isEmpty { path.removeLast() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .padding(.leading, 16)
                        .contentShape(Rectangle())
                }

                Spacer()
            }
        }
    }
}


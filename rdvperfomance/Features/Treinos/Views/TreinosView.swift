import SwiftUI

// MARK: - TELA DE TREINOS (genérica)
// Tela reutilizável para exibir conteúdo de treinos baseado no TreinoTipo.
// Mostra: header com título, imagem principal com overlay, e rodapé com ícone customizado do tipo.
struct TreinosView: View {

    // Binding para controlar navegação
    @Binding var path: [AppRoute]

    // Tipo de treino atual (Crossfit, Academia ou Em Casa)
    let tipo: TreinoTipo

    // Alturas fixas para header e footer
    private let headerHeight: CGFloat = 52
    private let footerHeight: CGFloat = 70

    var body: some View {
        ZStack {

            // Fundo fixo da tela
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header com título do tipo de treino e botão voltar
                headerBar(title: tipo.titulo)
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.70))

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
                footerBarTreinos()
                    .frame(height: footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.75))
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
                .font(.system(size: 17, weight: .semibold))
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

    // MARK: - FOOTER BAR (Treinos)
    // Rodapé padrão das telas de treino:
    // Home | Treinos (customizado de acordo com o tipo) | Sobre
    private func footerBarTreinos() -> some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.2))

            HStack(spacing: 28) {

                // Vai para Home limpando toda a pilha
                Button {
                    path.removeAll()
                    path.append(.home)
                } label: {
                    footerItem(icon: "house", title: "Home", isSelected: false)
                }
                .buttonStyle(.plain)

                // Item central com ícone custom e título do tipo
                footerItemCustom(iconView: {
                    tipo.iconeRodapeTreinos
                }, title: tipo.titulo, isSelected: true)

                // Vai para Sobre
                Button {
                    path.append(.sobre)
                } label: {
                    footerItem(icon: "bubble.left", title: "Sobre", isSelected: false)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
        }
    }

    // Item padrão do rodapé com SF Symbol
    private func footerItem(icon: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(isSelected ? .green : .white.opacity(0.7))
        .frame(width: 110)
    }

    // Item do rodapé que aceita qualquer View como ícone (customização do TreinoTipo)
    private func footerItemCustom<Icon: View>(
        @ViewBuilder iconView: () -> Icon,
        title: String,
        isSelected: Bool
    ) -> some View {
        VStack(spacing: 6) {
            iconView()
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundColor(isSelected ? .green : .white.opacity(0.7))
        .frame(width: 110)
    }
}


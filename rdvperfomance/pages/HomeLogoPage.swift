import SwiftUI

// MARK: - TELA SOBRE (HomeLogoPage)
// Tela institucional do app (Sobre).
// Exibe informações do aplicativo e mantém header/footer fixos.
struct HomeLogoPage: View {

    // ✅ Navegação controlada via NavigationStack
    @Binding var path: [AppRoute]

    // MARK: - Layout
    private let headerHeight: CGFloat = 52
    private let footerHeight: CGFloat = 70
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
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.70))

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
                footerViewSomenteHomeSobre()
                    .frame(height: footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.75))
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
                .font(.system(size: 17, weight: .semibold))
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
        .background(Color.black.opacity(0.65))
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

    // MARK: - FOOTER (IGUAL AO DA HOME)
    // Rodapé com a mesma formatação da Home:
    // Home (ação) | Espaço central | Sobre (ação)
    // Nesta tela, "Sobre" fica selecionado.
    private func footerViewSomenteHomeSobre() -> some View {
        VStack(spacing: 0) {

            Divider()
                .background(Color.white.opacity(0.2))

            HStack(spacing: 28) {

                // Botão Home: limpa pilha e vai para Home
                Button {
                    goHome()
                } label: {
                    footerItem(icon: "house", title: "Home", isSelected: false)
                }
                .buttonStyle(.plain)

                // Placeholder do meio para manter alinhamento visual (igual ao HomePage)
                Color.clear
                    .frame(width: 88, height: 1)

                // Botão Sobre: aqui fica selecionado e não precisa navegar (mas mantém padrão)
                Button {
                    // Evita empilhar várias vezes a mesma rota "sobre"
                    if path.last != .sobre {
                        path.append(.sobre)
                    }
                } label: {
                    footerItem(icon: "bubble.left", title: "Sobre", isSelected: true)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 10)
        }
    }

    // Volta para Home limpando a pilha (padrão consistente com outras telas)
    private func goHome() {
        path.removeAll()
        path.append(.home)
    }

    // Item padrão do rodapé (ícone + texto)
    private func footerItem(icon: String, title: String, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))

            Text(title)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(isSelected ? .green : .white.opacity(0.7))
        .frame(width: 88)
    }
}


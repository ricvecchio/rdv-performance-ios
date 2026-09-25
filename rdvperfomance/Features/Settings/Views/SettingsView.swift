import SwiftUI

// Tela de configurações do aplicativo
struct SettingsView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    private let contentMaxWidth: CGFloat = 380

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Constrói a interface da tela de configurações
    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Rectangle()
                    .fill(Theme.Colors.divider)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)

                ScrollView(showsIndicators: false) {
                    HStack {
                        Spacer(minLength: 0)

                        VStack(alignment: .leading, spacing: 16) {

                            sectionTitle("CONTA")
                            accountCard()

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

                footerForUser()
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
            }
            .ignoresSafeArea(.container, edges: [.bottom])
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { pop() } label: {
                    ZStack {
                        Color.clear
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .foregroundColor(.green)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Configurações")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }

        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)

    }

    @ViewBuilder
    private func footerForUser() -> some View {
        if session.isStudent {
            FooterBar(
                path: $path,
                kind: .studentHomeTreinosRecordsProfile(
                    isHomeSelected: false,
                    isTreinosSelected: false,
                    isRecordsSelected: false,
                    isPerfilSelected: false
                )
            )
        } else {
            FooterBar(
                path: $path,
                kind: .teacherHomeAlunosSobrePerfil(
                    selectedCategory: categoriaAtualProfessor,
                    isHomeSelected: false,
                    isAlunosSelected: false,
                    isSobreSelected: false,
                    isPerfilSelected: true
                )
            )
        }
    }

    // Volta uma tela usando dismiss nativo do SwiftUI. Como Settings é
    // sempre apresentado por NavigationStack, esse é o pop mais confiável
    // para evitar toque perdido por mutação manual de `path`.
    private func pop() {
        dismiss()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.35))
            .padding(.horizontal, 6)
    }

    private func accountCard() -> some View {
        card {
            cardRow(icon: "person.crop.circle", title: "Editar Perfil") {
                path.append(.editarPerfil)
            }
            divider()
            cardRow(icon: "key.fill", title: "Alterar Senha") {
                path.append(.alterarSenha)
            }
            divider()
            cardRow(icon: "trash.fill", title: "Excluir Conta") {
                path.append(.excluirConta)
            }
        }
    }

    private func supportLegalCard() -> some View {
        card {

            cardRow(icon: "info.circle.fill", title: "Sobre") {
                path.append(.sobre)
            }

            divider()

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
            divider()

            cardRow(icon: "gamecontroller.fill", title: "Preview do Progresso") {
                path.append(.spriteDemo)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
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

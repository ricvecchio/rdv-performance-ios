// Tela que exibe informações sobre o aplicativo
import SwiftUI
import UIKit

// View da tela Sobre com card de informações e funcionalidades
struct AboutView: View {

    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    private let cardMaxWidth: CGFloat = 360
    private let logoLift: CGFloat = 30
    private let cardLift: CGFloat = 26

    @AppStorage("ultimoTreinoSelecionado")
    private var ultimoTreinoSelecionado: String = TreinoTipo.crossfit.rawValue

    // Retorna a categoria selecionada pelo professor
    private var categoriaAtualProfessor: TreinoTipo {
        TreinoTipo(rawValue: ultimoTreinoSelecionado) ?? .crossfit
    }

    // Constrói a interface da tela Sobre
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
                    VStack(spacing: 16) {

                        Color.clear.frame(height: 8)

                        Image("rdv_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260)
                            .padding(.top, -logoLift)

                        contentCard()
                            .frame(maxWidth: cardMaxWidth)
                            .padding(.top, -38 - cardLift)

                        Color.clear.frame(height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }

                footerForUser()
                    .frame(height: Theme.Layout.footerHeight)
                    .frame(maxWidth: .infinity)
                    .background(Theme.Colors.footerBackground)
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
                Text("Sobre")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HeaderAvatarView(size: 38)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Retorna o footer apropriado baseado no tipo de usuário
    @ViewBuilder
    private func footerForUser() -> some View {
        if session.userType == .STUDENT {
            FooterBar(
                path: $path,
                kind: .agendaSobrePerfil(
                    isAgendaSelected: false,
                    isSobreSelected: false, // ✅ Agora "Sobre" não existe no rodapé do aluno (virou "Recordes")
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
                    isSobreSelected: true,
                    isPerfilSelected: false
                )
            )
        }
    }

    // Remove a última rota da pilha para voltar
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Retorna o card com informações do app
    private func contentCard() -> some View {
        VStack(spacing: 14) {
            Text("GERENCIE SEUS ALUNOS E PERSONALIZE TREINOS COM FACILIDADE")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureItem("Crie treinos personalizados para seus alunos")
                featureItem("Acompanhe a evolução de cada aluno baseado no programa selecionado")
                featureItem("Tudo em um só lugar com interface intuitiva e prática")
            }

            Text("Sua ferramenta para otimizar o acompanhamento dos seus alunos e seus treinos!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.92))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(12)
    }

    // Retorna uma linha com ícone de check e texto descritivo
    private func featureItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .foregroundColor(.white)
        }
    }
}


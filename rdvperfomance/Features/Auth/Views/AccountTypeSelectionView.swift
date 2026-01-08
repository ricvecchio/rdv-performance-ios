// Tela de seleção de tipo de conta (aluno ou professor)
import SwiftUI

struct AccountTypeSelectionView: View {

    @Binding var path: [AppRoute]

    private let textSecondary = Color.white.opacity(0.60)

    // Interface principal com logo e botões de seleção
    var body: some View {
        ZStack {

            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 20)

                Text("Escolha seu perfil")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {

                    selectionButton(
                        title: "Sou Aluno",
                        subtitle: "Acompanhe seus treinos e progresso"
                    ) {
                        path.append(.registerStudent)
                    }

                    selectionButton(
                        title: "Sou Professor",
                        subtitle: "Envie treinos e acompanhe alunos"
                    ) {
                        path.append(.registerTrainer)
                    }
                }
                .frame(width: 300)

                Text("Você pode trocar depois nas configurações.")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
                    .padding(.top, 18)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Cadastro")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Retorna botão estilizado para seleção de tipo de usuário
    private func selectionButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }
            .frame(width: 300, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }

    // Remove a última rota da pilha de navegação
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}

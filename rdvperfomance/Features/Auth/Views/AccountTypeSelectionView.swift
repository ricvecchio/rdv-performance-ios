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

                Text("auth.account_type.prompt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 22)

                VStack(spacing: 14) {

                    selectionButton(
                        title: "auth.account_type.student.title",
                        subtitle: "auth.account_type.student.subtitle"
                    ) {
                        path.append(.registerStudent)
                    }

                    selectionButton(
                        title: "auth.account_type.trainer.title",
                        subtitle: "auth.account_type.trainer.subtitle"
                    ) {
                        path.append(.registerTrainer)
                    }
                }
                .frame(width: 300)

                Text("auth.account_type.change_note")
                    .font(.system(size: 13))
                    .foregroundColor(textSecondary)
                    .padding(.top, 18)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
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
                Text("auth.registration.title")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Retorna botão estilizado para seleção de tipo de usuário
    private func selectionButton(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
            }
            .frame(width: 300, height: 74)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.68))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.Colors.primaryGreen.opacity(0.28), lineWidth: 1)
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

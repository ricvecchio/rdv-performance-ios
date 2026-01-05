// ChangePasswordView.swift — Tela para alteração de senha com validações e feedbacks
import SwiftUI

struct ChangePasswordView: View {

    // Binding de rotas e sessão
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    // Campos do formulário
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)
    private let contentMaxWidth: CGFloat = 380

    // Corpo da tela com header, formulário e ações
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

                        VStack(spacing: 16) {

                            headerCard()
                            formCard()
                            actionCard()

                            if showError {
                                feedbackCard(text: errorMessage, isError: true)
                            }

                            if showSuccess {
                                feedbackCard(text: "Senha alterada com sucesso.", isError: false)
                            }

                            Color.clear.frame(height: 18)
                        }
                        .frame(maxWidth: contentMaxWidth)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
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
                .buttonStyle(.plain)
            }

            ToolbarItem(placement: .principal) {
                Text("Alterar Senha")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Header informativo da tela
    private func headerCard() -> some View {
        VStack(spacing: 10) {
            Text("Segurança")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.92))

            Text("Para alterar sua senha, confirme a senha atual e defina uma nova senha.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Card do formulário com campos seguros
    private func formCard() -> some View {
        VStack(spacing: 18) {

            secureUnderlineField(title: "Senha atual", text: $currentPassword)
            secureUnderlineField(title: "Nova senha", text: $newPassword)
            secureUnderlineField(title: "Confirmar nova senha", text: $confirmNewPassword)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Área de ações com botão salvar e cancelar
    private func actionCard() -> some View {
        VStack(spacing: 10) {

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .foregroundColor(.white.opacity(0.9))

                    Text(isLoading ? "Salvando..." : "Salvar nova senha")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.green.opacity(0.10), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            Button { pop() } label: {
                Text("Cancelar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Feedback visual para sucesso/erro
    private func feedbackCard(text: String, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background((isError ? Color.red : Color.green).opacity(0.20))
            .cornerRadius(12)
    }

    // Submete alteração de senha com validações locais e chamada ao serviço
    private func submit() async {
        showError = false
        showSuccess = false
        errorMessage = ""

        let cp = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let np = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let cn = confirmNewPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard session.isLoggedIn else {
            presentError("Você precisa estar logado.")
            return
        }

        guard !cp.isEmpty, !np.isEmpty, !cn.isEmpty else {
            presentError("Preencha todos os campos.")
            return
        }

        guard np.count >= 6 else {
            presentError("A nova senha deve ter pelo menos 6 caracteres.")
            return
        }

        guard np == cn else {
            presentError("A confirmação da nova senha não confere.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AccountSecurityService.shared.changePassword(currentPassword: cp, newPassword: np)

            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
            showSuccess = true

        } catch {
            presentError(error.localizedDescription)
        }
    }

    // Mostra erro na UI
    private func presentError(_ message: String) {
        showError = true
        errorMessage = message
    }

    // Navegação: volta uma rota
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Componentes: campo seguro com underline
    private func secureUnderlineField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            SecureField("", text: text)
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding(.vertical, 10)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }
}

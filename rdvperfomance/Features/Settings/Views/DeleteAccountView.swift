// DeleteAccountView.swift — Tela para exclusão permanente de conta com confirmação e validação
import SwiftUI

struct DeleteAccountView: View {

    // Binding de rotas e sessão
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: AppSession

    // Campos do formulário
    @State private var currentPassword: String = ""
    @State private var confirmText: String = ""

    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)
    private let contentMaxWidth: CGFloat = 380

    // Valida se a ação pode ser executada
    private var canDelete: Bool {
        !currentPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && confirmText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "EXCLUIR"
        && !isLoading
    }

    // Corpo com aviso, formulário e ações
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

                            warningCard()
                            formCard()
                            actionCard()

                            if showError {
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.25))
                                    .cornerRadius(12)
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
                .disabled(isLoading)
            }

            ToolbarItem(placement: .principal) {
                Text("Excluir Conta")
                    .font(Theme.Fonts.headerTitle())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .toolbarBackground(Theme.Colors.headerBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Card de aviso sobre a ação permanente
    private func warningCard() -> some View {
        VStack(spacing: 10) {

            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red.opacity(0.9))
                Text("Atenção")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.92))
                Spacer()
            }

            Text("Esta ação é permanente. Seu acesso será removido e você será deslogado do aplicativo.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.60))
                .multilineTextAlignment(.leading)

            Text("Para confirmar, digite EXCLUIR e informe sua senha atual.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Formulário com senha e confirmação
    private func formCard() -> some View {
        VStack(spacing: 18) {

            secureUnderlineField(title: "Senha atual", text: $currentPassword)

            underlineField(title: "Digite EXCLUIR para confirmar", text: $confirmText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(14)
    }

    // Área de ações com botão excluir e cancelar
    private func actionCard() -> some View {
        VStack(spacing: 10) {

            Button {
                Task { await submitDelete() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white.opacity(0.9))

                    Text(isLoading ? "Excluindo..." : "Excluir minha conta")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.28))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .shadow(color: Color.red.opacity(0.10), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canDelete)

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

    // Submete exclusão chamando o serviço e trata feedback
    private func submitDelete() async {
        showError = false
        errorMessage = ""

        guard session.isLoggedIn else {
            presentError("Você precisa estar logado.")
            return
        }

        let pw = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pw.isEmpty else {
            presentError("Informe sua senha atual.")
            return
        }

        guard confirmText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "EXCLUIR" else {
            presentError("Digite EXCLUIR para confirmar.")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await AccountSecurityService.shared.deleteAccount(currentPassword: pw)

            // Após deletar, limpa caminho para forçar flow de login
            path.removeAll()

        } catch {
            presentError(error.localizedDescription)
        }
    }

    // Mostra erro na UI
    private func presentError(_ message: String) {
        showError = true
        errorMessage = message
    }

    // Navegação: voltar
    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    // Componentes: campos com underline
    private func underlineField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)

            TextField("", text: text)
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .padding(.vertical, 10)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

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

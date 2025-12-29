import SwiftUI

// MARK: - LOGIN
// Tela de login do app.
// Possui campos de e-mail e senha e navega para Home quando ambos estão preenchidos.
struct LoginView: View {

    // Binding da navegação centralizada
    @Binding var path: [AppRoute]

    // Estados de formulário
    @State private var email: String = ""
    @State private var password: String = ""

    // Controla exibição/ocultação da senha
    @State private var showPassword: Bool = false

    // Cores de estilo da tela
    private let textSecondary = Color.white.opacity(0.60)
    private let lineColor = Color.white.opacity(0.35)

    var body: some View {
        ZStack {

            // Fundo da tela
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // LOGO
                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 20)

                // Texto auxiliar
                Text("Entre com sua conta")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                    .padding(.bottom, 18)

                // Campos
                VStack(spacing: 22) {

                    UnderlineTextField(
                        title: "E-mail",
                        text: $email,
                        isSecure: false,
                        showPassword: .constant(false),
                        lineColor: lineColor,
                        textColor: .white,
                        placeholderColor: textSecondary
                    )

                    UnderlineTextField(
                        title: "Senha",
                        text: $password,
                        isSecure: true,
                        showPassword: $showPassword,
                        lineColor: lineColor,
                        textColor: .white,
                        placeholderColor: textSecondary
                    )
                }
                .frame(width: 260)

                // Recuperar senha (placeholder)
                Button { } label: {
                    Text("Esqueceu a senha?")
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                        .padding(.top, 14)
                }
                .buttonStyle(.plain)

                // Botão principal
                Button {
                    validarLogin()
                } label: {
                    Text("Acessar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 260, height: 44)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.28))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .shadow(
                            color: Color.green.opacity(0.10),
                            radius: 10,
                            x: 0,
                            y: 6
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 30)

                // ✅ Abre Tela 1 (Seleção Aluno/Professor)
                Button {
                    path.append(.accountTypeSelection)
                } label: {
                    Text("Inscreva-se gratuitamente")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .underline()
                        .padding(.top, 18)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Validação do login (MVP)
    private func validarLogin() {
        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailTrim.isEmpty, !passwordTrim.isEmpty else { return }

        // MVP: navega direto
        path.append(.home)
    }
}


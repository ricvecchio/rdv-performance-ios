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
    private let buttonBackground = Color(red: 0.22, green: 0.33, blue: 0.18)
    private let buttonText = Color.white.opacity(0.92)

    var body: some View {
        ZStack {

            // Fundo da tela
            Image("rdv_fundo")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Logo do app
                Image("rdv_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
                    .padding(.top, 60)

                // Texto auxiliar
                Text("Entre com sua conta")
                    .font(.system(size: 17))
                    .foregroundColor(textSecondary)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                // Campos
                VStack(spacing: 22) {

                    // Campo de e-mail
                    UnderlineTextField(
                        title: "E-mail",
                        text: $email,
                        isSecure: false,
                        showPassword: .constant(false), // não usado no modo e-mail
                        lineColor: lineColor,
                        textColor: .white,
                        placeholderColor: textSecondary
                    )

                    // Campo de senha (com botão olho)
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

                // Ação futura: recuperar senha
                Button { } label: {
                    Text("Esqueceu a senha?")
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                        .padding(.top, 18)
                }
                .buttonStyle(.plain)

                // Botão principal de login
                Button {
                    validarLogin()
                } label: {
                    Text("Acessar")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(buttonText)
                        .frame(width: 260, height: 50)
                        .background(Capsule().fill(buttonBackground.opacity(0.75)))
                }
                .padding(.top, 20)

                Spacer()
            }
        }
        // Remove navegação padrão
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Validação do login
    // Validação simples: se e-mail e senha estiverem preenchidos, navega para Home.
    // Aqui é o local ideal para integrar autenticação real via API.
    private func validarLogin() {
        let emailTrim = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrim = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailTrim.isEmpty, !passwordTrim.isEmpty else { return }

        path.append(.home)
    }
}


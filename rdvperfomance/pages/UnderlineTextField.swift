import SwiftUI

// MARK: - COMPONENTE REUTILIZÁVEL (TextField com linha)
// Este componente cria um campo de texto com estilo "underline" (linha embaixo).
// Ele pode funcionar como campo normal (TextField) ou campo de senha (SecureField),
// com opção de mostrar/ocultar a senha através do ícone de "olho".
struct UnderlineTextField: View {

    // Título exibido acima do campo (ex.: "E-mail", "Senha")
    let title: String

    // Binding do texto digitado (o valor fica sincronizado com a tela pai)
    @Binding var text: String

    // Define se o campo é seguro (senha) ou normal
    let isSecure: Bool

    // Controla se a senha está visível (true) ou oculta (false)
    @Binding var showPassword: Bool

    // Cores configuráveis para reaproveitar o componente em outras telas
    let lineColor: Color
    let textColor: Color
    let placeholderColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Label do campo
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(placeholderColor)

            // Campo com ícone do "olho" (apenas quando for senha)
            ZStack(alignment: .trailing) {

                // Alterna entre SecureField e TextField conforme showPassword
                Group {
                    if isSecure && !showPassword {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .foregroundColor(textColor)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(title == "E-mail" ? .emailAddress : .default)

                // Botão para mostrar/ocultar senha
                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(placeholderColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Linha inferior (underline)
            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }
}


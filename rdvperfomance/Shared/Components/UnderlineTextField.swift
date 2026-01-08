// Campo de texto customizado com linha inferior e suporte para senha
import SwiftUI

// TextField com estilo personalizado e opção de mostrar/ocultar senha
struct UnderlineTextField: View {

    // Título exibido acima do campo
    let title: String

    // Texto digitado no campo
    @Binding var text: String

    // Define se o campo exibe asteriscos para senha
    let isSecure: Bool

    // Controla visibilidade da senha
    @Binding var showPassword: Bool

    // Cores configuráveis do componente
    let lineColor: Color
    let textColor: Color
    let placeholderColor: Color

    // Constrói o campo com label, input e linha inferior
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(placeholderColor)

            ZStack(alignment: .trailing) {

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

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }
}

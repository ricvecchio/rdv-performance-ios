// Campo de texto customizado com linha inferior e suporte para senha
import SwiftUI

// TextField com estilo personalizado e opção de mostrar/ocultar senha
struct UnderlineTextField: View {

    // Título exibido acima do campo
    let title: LocalizedStringKey
    let isEmail: Bool

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

    init(
        title: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool,
        showPassword: Binding<Bool>,
        lineColor: Color,
        textColor: Color,
        placeholderColor: Color,
        isEmail: Bool = false
    ) {
        self.title = title
        _text = text
        self.isSecure = isSecure
        _showPassword = showPassword
        self.lineColor = lineColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.isEmail = isEmail
    }

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
                .keyboardType(isEmail ? .emailAddress : .default)

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

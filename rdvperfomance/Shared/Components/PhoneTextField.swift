import SwiftUI

/// Campo de texto para número de telefone com máscara brasileira aplicada em tempo real.
///
/// O binding `digits` armazena **apenas os dígitos** normalizados (ex.: `"11988888888"`).
/// A exibição é formatada automaticamente: `"(11) 98888-8888"`.
///
/// Compatível com valores legados já formatados: ao receber `"(11) 98888-8888"` no binding,
/// o componente normaliza internamente e exibe corretamente.
///
/// Uso:
/// ```swift
/// @State private var phoneDigits: String = ""
///
/// PhoneTextField(
///     title: "WhatsApp (opcional)",
///     digits: $phoneDigits
/// )
/// ```
struct PhoneTextField: View {

    let title: String
    @Binding var digits: String

    var lineColor: Color       = Color.white.opacity(0.35)
    var textColor: Color       = .white
    var placeholderColor: Color = Color.white.opacity(0.60)
    var isMobileNumber: Bool = false

    init(
        title: String,
        digits: Binding<String>,
        lineColor: Color = Color.white.opacity(0.35),
        textColor: Color = .white,
        placeholderColor: Color = Color.white.opacity(0.60),
        isMobileNumber: Bool = false
    ) {
        self.title = title
        self._digits = digits
        self.lineColor = lineColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.isMobileNumber = isMobileNumber
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(placeholderColor)

            TextField("", text: Binding(
                get: {
                    isMobileNumber
                        ? BrazilianPhoneFormatter.formatMobile(digits)
                        : BrazilianPhoneFormatter.format(digits)
                },
                set: { newValue in
                    digits = BrazilianPhoneFormatter.normalize(newValue)
                }
            ))
            .foregroundColor(textColor)
            .font(.system(size: 16))
            .keyboardType(.phonePad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }
}

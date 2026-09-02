import SwiftUI
import UIKit

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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(placeholderColor)

            BrazilianPhoneTextField(digits: $digits, textColor: textColor)
                .frame(height: 22)

            Rectangle()
                .fill(lineColor)
                .frame(height: 1)
        }
    }

    private struct BrazilianPhoneTextField: UIViewRepresentable {

        @Binding var digits: String
        let textColor: Color

        func makeUIView(context: Context) -> UITextField {
            let textField = UITextField()
            textField.delegate = context.coordinator
            textField.font = .systemFont(ofSize: 16)
            textField.textColor = UIColor(textColor)
            textField.keyboardType = .phonePad
            textField.autocorrectionType = .no
            textField.autocapitalizationType = .none
            textField.borderStyle = .none
            textField.text = BrazilianPhoneFormatter.formatMobile(digits)
            return textField
        }

        func updateUIView(_ textField: UITextField, context: Context) {
            let formatted = BrazilianPhoneFormatter.formatMobile(digits)
            if textField.text != formatted {
                textField.text = formatted
            }
            textField.textColor = UIColor(textColor)
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }

        final class Coordinator: NSObject, UITextFieldDelegate {

            private let parent: BrazilianPhoneTextField

            init(parent: BrazilianPhoneTextField) {
                self.parent = parent
            }

            func textField(
                _ textField: UITextField,
                shouldChangeCharactersIn range: NSRange,
                replacementString string: String
            ) -> Bool {
                guard let range = Range(range, in: textField.text ?? "") else {
                    return false
                }

                let proposed = (textField.text ?? "").replacingCharacters(in: range, with: string)
                let proposedDigits = proposed.filter(\.isNumber)

                if proposedDigits.count > 11, string.count == 1 {
                    return false
                }

                let normalized = BrazilianPhoneFormatter.normalize(proposed)
                textField.text = BrazilianPhoneFormatter.formatMobile(normalized)
                parent.digits = normalized
                return false
            }
        }
    }
}

import Foundation

/// Formata e normaliza números de telefone no padrão brasileiro.
///
/// Formato celular (11 dígitos): `(XX) XXXXX-XXXX`
/// Formato fixo   (10 dígitos): `(XX) XXXX-XXXX`
///
/// A normalização extrai apenas dígitos e limita a 11 caracteres.
/// A validação aceita vazio, 10 ou 11 dígitos como entradas válidas.
struct BrazilianPhoneFormatter {

    // MARK: - Normalização

    /// Extrai apenas dígitos da entrada e limita a 11 caracteres.
    /// Entradas como `"(11) 98888-8888"` ou `"abc11988888888"` retornam `"11988888888"`.
    static func normalize(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        return String(digits.prefix(11))
    }

    // MARK: - Formatação

    /// Formata uma string (bruta ou já formatada) para exibição com máscara brasileira.
    ///
    /// Exemplos:
    /// - `"11988888888"` → `"(11) 98888-8888"`
    /// - `"1150505050"`  → `"(11) 5050-5050"`
    /// - `"abc11988888888"` → `"(11) 98888-8888"` (normaliza automaticamente)
    static func format(_ input: String) -> String {
        let digits = normalize(input)
        let count  = digits.count

        switch count {
        case 0:
            return ""
        case 1...2:
            return "(\(digits)"
        case 3...6:
            let area = String(digits.prefix(2))
            let rest = String(digits.dropFirst(2))
            return "(\(area)) \(rest)"
        case 7...10:
            // Telefone fixo: (XX) XXXX-XXXX
            let area = String(digits.prefix(2))
            let p1   = String(digits.dropFirst(2).prefix(4))
            let p2   = String(digits.dropFirst(6))
            return p2.isEmpty ? "(\(area)) \(p1)" : "(\(area)) \(p1)-\(p2)"
        default:
            // Celular: (XX) XXXXX-XXXX
            let area = String(digits.prefix(2))
            let p1   = String(digits.dropFirst(2).prefix(5))
            let p2   = String(digits.dropFirst(7))
            return "(\(area)) \(p1)-\(p2)"
        }
    }

    /// Formata um celular brasileiro, preservando cinco dígitos antes do hífen.
    static func formatMobile(_ input: String) -> String {
        let digits = normalize(input)
        let count = digits.count

        switch count {
        case 0:
            return ""
        case 1...2:
            return "(\(digits)"
        case 3...7:
            let area = String(digits.prefix(2))
            let rest = String(digits.dropFirst(2))
            return "(\(area)) \(rest)"
        default:
            let area = String(digits.prefix(2))
            let p1 = String(digits.dropFirst(2).prefix(5))
            let p2 = String(digits.dropFirst(7))
            return "(\(area)) \(p1)-\(p2)"
        }
    }

    // MARK: - Validação

    /// Retorna `true` quando o número (após normalização) é válido.
    /// Aceita: vazio, 10 dígitos (fixo) ou 11 dígitos (celular).
    static func isValid(_ input: String) -> Bool {
        let count = normalize(input).count
        return count == 0 || count == 10 || count == 11
    }

    /// Retorna `true` para vazio ou um número de celular completo (11 dígitos).
    static func isValidMobile(_ input: String) -> Bool {
        let count = normalize(input).count
        return count == 0 || count == 11
    }
}

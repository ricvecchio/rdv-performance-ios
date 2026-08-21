import Foundation

/// Parser e formatador de pesos para os records pessoais do aluno.
///
/// - Aceita vírgula ou ponto como separador decimal.
/// - Valida máximo de 2 casas decimais, valor não negativo e ausência de letras.
/// - Exibe com convenção brasileira: vírgula decimal, 2 casas fixas, seguido da unidade.
struct WeightParser {

    // MARK: - Parsing

    /// Converte texto do usuário para `Double`.
    ///
    /// Aceita:
    /// - `"183,7"`  → `183.7`
    /// - `"183.70"` → `183.7`
    /// - `"405"`    → `405.0`
    /// - `"405,00"` → `405.0`
    ///
    /// Rejeita (retorna `nil`):
    /// - Duas vírgulas ou dois pontos
    /// - Mais de 2 casas decimais
    /// - Letras ou caracteres inválidos
    /// - Valores negativos
    static func parse(_ input: String) -> Double? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Normaliza separador decimal: vírgula → ponto
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")

        // Só dígitos e ponto são permitidos
        let allowed = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))
        guard normalized.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }

        // Máximo 1 separador decimal
        let parts = normalized.components(separatedBy: ".")
        guard parts.count <= 2 else { return nil }

        // Máximo 2 casas decimais
        if parts.count == 2 {
            guard parts[1].count <= 2 else { return nil }
        }

        guard let value = Double(normalized), value >= 0 else { return nil }
        return value
    }

    // MARK: - Formatação

    /// Formata `Double` no padrão brasileiro com 2 casas decimais + unidade.
    ///
    /// Exemplos:
    /// - `display(183.7, unit: "kg")` → `"183,70 kg"`
    /// - `display(405.0, unit: "lb")` → `"405,00 lb"`
    static func display(_ value: Double, unit: String) -> String {
        "\(brazilianFormat(value)) \(unit)"
    }

    /// Formata `Double` no padrão brasileiro com 2 casas decimais.
    ///
    /// Exemplo: `brazilianFormat(183.7)` → `"183,70"`
    static func brazilianFormat(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        fmt.decimalSeparator = ","
        fmt.groupingSeparator = "."
        return fmt.string(from: NSNumber(value: value))
            ?? String(format: "%.2f", value).replacingOccurrences(of: ".", with: ",")
    }
}

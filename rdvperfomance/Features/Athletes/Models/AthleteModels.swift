import Foundation

/// Privacidade do perfil para o recurso Atletas. Valor padrão (ausente/desconhecido): privado.
enum AthletePrivacy: String, Hashable {
    case `public`
    case `private`

    init(storedValue raw: String?) {
        self = raw == AthletePrivacy.public.rawValue ? .public : .private
    }
}

/// Projeção pública mínima de um usuário (`publicAthletes/{uid}`).
/// Nunca contém e-mail, telefone, dados administrativos ou de autenticação.
struct PublicAthlete: Identifiable, Hashable {
    let id: String
    let name: String
    let photoThumbBase64: String?
    let privacy: AthletePrivacy
    let prCount: Int
}

/// Recorde publicado de um atleta com perfil público (somente leitura).
struct AthleteRecordItem: Identifiable, Hashable {
    let categoryKey: String
    let itemKey: String
    let name: String
    /// Texto do resultado (categorias de tempo/repetições) ou valor numérico em kg (`unit == "kg"`).
    let value: String
    let unit: String

    var id: String { "\(categoryKey)/\(itemKey)" }
    var isWeightKg: Bool { unit == "kg" }
}

struct AthleteRecordCategory: Identifiable, Hashable {
    let key: String
    let items: [AthleteRecordItem]

    var id: String { key }
}

/// Normalização de textos para a busca (sem acentos, minúsculas) e prefixos de pesquisa.
enum AthleteSearchText {
    static let maxPrefixLength = 20
    private static let maxPrefixCount = 150

    static func normalize(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func words(_ text: String) -> [String] {
        normalize(text)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    /// Todos os prefixos (até 20 caracteres) de cada palavra do nome, para busca por início de palavra.
    static func prefixes(for name: String) -> [String] {
        var result = [String]()
        var seen = Set<String>()

        for word in words(name) {
            let limited = String(word.prefix(maxPrefixLength))
            var current = ""
            for character in limited {
                current.append(character)
                if seen.insert(current).inserted {
                    result.append(current)
                }
                if result.count >= maxPrefixCount { return result }
            }
        }

        return result
    }
}


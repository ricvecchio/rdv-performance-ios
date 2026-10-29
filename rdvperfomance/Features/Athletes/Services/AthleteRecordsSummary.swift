import Foundation

/// Resume os payloads de Personal Records (os mesmos sincronizados com `users/{uid}/student_personal_records`)
/// em uma lista simples de recordes com resultado válido, por categoria.
///
/// Regras:
/// - Somente movimentos/provas com resultado salvo (texto não vazio ou número > 0 no Barbell).
/// - Itens sem resultado, categorias vazias e históricos não entram no resumo.
/// - Um movimento conta uma única vez, independentemente de quantas atualizações históricas possua.
enum AthleteRecordsSummary {

    private struct CategoryConfig {
        let key: String
        let valuesKey: String
        let customKey: String
        let isNumeric: Bool
    }

    private static let categories: [CategoryConfig] = [
        .init(key: "barbell", valuesKey: "student_pr_barbell_values_v1", customKey: "student_pr_barbell_custom_moves_v1", isNumeric: true),
        .init(key: "gymnastic", valuesKey: "student_pr_gymnastic_values_v1", customKey: "student_pr_gymnastic_custom_items_v1", isNumeric: false),
        .init(key: "endurance", valuesKey: "student_pr_endurance_values_v1", customKey: "student_pr_endurance_custom_items_v1", isNumeric: false),
        .init(key: "notables", valuesKey: "student_pr_notables_values_v1", customKey: "student_pr_notables_custom_items_v1", isNumeric: false),
        .init(key: "girls", valuesKey: "student_pr_girls_values_v1", customKey: "student_pr_girls_custom_items_v1", isNumeric: false),
        .init(key: "open", valuesKey: "student_pr_open_values_v1", customKey: "student_pr_open_custom_items_v1", isNumeric: false),
        .init(key: "heroes", valuesKey: "student_pr_heroes_values_v1", customKey: "student_pr_heroes_custom_items_v1", isNumeric: false),
        .init(key: "campeonatos", valuesKey: "student_pr_campeonatos_values_v1", customKey: "student_pr_campeonatos_custom_items_v1", isNumeric: false),
        .init(key: "crossfit_games", valuesKey: "student_pr_crossfit_games_values_v1", customKey: "student_pr_crossfit_games_custom_items_v1", isNumeric: false)
    ]

    static func build(from payloads: [String: Data]) -> [AthleteRecordCategory] {
        categories.compactMap { config in
            let customNames = self.customNames(from: payloads[config.customKey])
            let items = self.items(for: config, values: payloads[config.valuesKey], customNames: customNames)
            return items.isEmpty ? nil : AthleteRecordCategory(key: config.key, items: items)
        }
    }

    // MARK: - Itens

    private static func items(
        for config: CategoryConfig,
        values: Data?,
        customNames: [String: String]
    ) -> [AthleteRecordItem] {
        guard let values, !values.isEmpty else { return [] }

        var raw = [String: String]()
        var unit = ""

        if config.isNumeric {
            guard let map = try? JSONDecoder().decode([String: Double].self, from: values) else { return [] }
            for (key, number) in map where number.isFinite && number > 0 {
                raw[key] = String(number)
            }
            unit = "kg"
        } else {
            guard let map = try? JSONDecoder().decode([String: String].self, from: values) else { return [] }
            for (key, text) in map {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { raw[key] = trimmed }
            }
        }

        return raw
            .map { key, value in
                AthleteRecordItem(
                    categoryKey: config.key,
                    itemKey: key,
                    name: customNames[key] ?? humanized(key),
                    value: value,
                    unit: unit
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func customNames(from data: Data?) -> [String: String] {
        guard let data, !data.isEmpty,
              let array = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else {
            return [:]
        }

        var result = [String: String]()
        for item in array {
            guard let key = item["storageKey"] as? String,
                  let name = item["name"] as? String,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                continue
            }
            result[key] = name
        }
        return result
    }

    /// Movimentos nativos são guardados somente pela chave (ex.: `back_squat`).
    private static func humanized(_ key: String) -> String {
        key
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    // MARK: - Documento Firestore

    static func documentItems(for category: AthleteRecordCategory) -> [[String: Any]] {
        category.items.map {
            [
                "key": $0.itemKey,
                "name": $0.name,
                "value": $0.value,
                "unit": $0.unit
            ]
        }
    }

    static func items(fromDocument data: [String: Any], categoryKey: String) -> [AthleteRecordItem] {
        guard let array = data["items"] as? [[String: Any]] else { return [] }

        return array.compactMap { dictionary in
            guard let key = dictionary["key"] as? String,
                  let name = dictionary["name"] as? String,
                  let value = dictionary["value"] as? String,
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return nil
            }

            return AthleteRecordItem(
                categoryKey: categoryKey,
                itemKey: key,
                name: name,
                value: value,
                unit: dictionary["unit"] as? String ?? ""
            )
        }
    }
}


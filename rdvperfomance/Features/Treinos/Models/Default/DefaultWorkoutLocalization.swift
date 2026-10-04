import Foundation

enum DefaultWorkoutLocalization {
    private static let sectionsByCategory: [TreinoTipo: [String]] = [
        .crossfit: [
            "girlsWods", "heroTributeWorkouts", "openWods",
            "wodsNomeados", "qualifiersCompeticoes"
        ],
        .academia: ["peito", "costas", "pernas", "ombros", "bracos", "core", "fullBody"],
        .emCasa: ["peito", "costas", "pernas", "ombros", "bracos", "core", "fullBody"]
    ]

    private struct Entry {
        let key: String
        let seed: DefaultWorkoutSeed
    }

    private static let entriesByCategory: [TreinoTipo: [String: [Entry]]] = Dictionary(
        uniqueKeysWithValues: sectionsByCategory.map { category, sections in
            (category, Dictionary(uniqueKeysWithValues: sections.map { section in
                (section, DefaultWorkoutsProvider.defaultsFor(category: category, sectionKey: section).map {
                    Entry(key: defaultKey(for: $0, sectionKey: section, category: category), seed: $0)
                })
            }))
        }
    )

    // Identity uses the seed's stable name, never its translated presentation.
    static func defaultKey(
        for seed: DefaultWorkoutSeed,
        sectionKey: String,
        category: TreinoTipo = .crossfit
    ) -> String {
        let slug = seed.name.lowercased().unicodeScalars.map {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains($0)
                ? String($0) : "_"
        }.joined().split(separator: "_").joined(separator: "_")
        return "default_workout.\(category.rawValue).\(sectionKey).\(slug)"
    }

    static func persistedDescription(for seed: DefaultWorkoutSeed) -> String {
        [seed.title, seed.description]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    static func resolvedKey(for template: WorkoutTemplateFS) -> String? {
        entry(for: template)?.key
    }

    static func presentation(for template: WorkoutTemplateFS, locale: Locale) -> WorkoutTemplateFS {
        guard let entry = entry(for: template) else { return template }
        let seed = entry.seed
        var result = template
        if matchesLegacyText(template.title, seed.name) {
            let category = TreinoTipo.normalized(from: template.categoryRaw)
            let titleComponent = category == .crossfit ? "name" : "title"
            result.title = localized("\(entry.key).\(titleComponent)", fallback: template.title, locale: locale)
        } else if matchesLegacyText(template.title, seed.title) {
            result.title = localized("\(entry.key).title", fallback: template.title, locale: locale)
        }
        if matchesLegacyText(template.description, persistedDescription(for: seed)) {
            result.description = [
                localized("\(entry.key).title", fallback: seed.title, locale: locale),
                localized("\(entry.key).description", fallback: seed.description, locale: locale)
            ].filter { !$0.isEmpty }.joined(separator: "\n")
        } else if matchesLegacyText(template.description, seed.description) {
            result.description = localized(
                "\(entry.key).description", fallback: template.description, locale: locale
            )
        }
        result.blocks = template.blocks?.map { block in
            // A default marker identifies origin, not permission to overwrite custom edits.
            guard let original = seed.blocks.first(where: {
                matchesLegacyText($0.title, block.name)
            }) else {
                return block
            }
            var localizedBlock = block
            localizedBlock.name = localized(
                "\(entry.key).block.\(original.order).name", fallback: block.name, locale: locale
            )
            if matchesLegacyText(block.details, original.text) {
                localizedBlock.details = localized(
                    "\(entry.key).block.\(original.order).details", fallback: block.details, locale: locale
                )
            }
            return localizedBlock
        }
        return result
    }

    private static func entry(for template: WorkoutTemplateFS) -> Entry? {
        guard let category = TreinoTipo.normalized(from: template.categoryRaw),
              let entries = entriesByCategory[category]?[template.sectionKey] else { return nil }
        if let key = template.defaultKey {
            return entries.first { $0.key == key }
        }
        // Legacy documents have random IDs. Match every persisted field, ignoring only block IDs.
        return entries.first { entry in
            let seed = entry.seed
            guard matchesLegacyText(template.title, seed.name) || matchesLegacyText(template.title, seed.title),
                  matchesLegacyText(template.description, persistedDescription(for: seed))
                    || matchesLegacyText(template.description, seed.description),
                  let blocks = template.blocks else { return false }
            let originals = seed.blocks.sorted { $0.order < $1.order }
            return blocks.count == originals.count && zip(blocks, originals).allSatisfy {
                matchesLegacyText($0.0.name, $0.1.title)
                    && matchesLegacyText($0.0.details, $0.1.text)
            }
        }
    }

    private static func matchesLegacyText(_ lhs: String, _ rhs: String) -> Bool {
        normalizedLegacyText(lhs) == normalizedLegacyText(rhs)
    }

    private static func normalizedLegacyText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func localized(_ key: String, fallback: String, locale: Locale) -> String {
        let value = AppLocalization.string(String.LocalizationValue(key), locale: locale)
        return value == key ? fallback : value
    }
}

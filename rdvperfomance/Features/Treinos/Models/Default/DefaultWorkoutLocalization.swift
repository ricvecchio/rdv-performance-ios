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
        let category: TreinoTipo
        let seed: DefaultWorkoutSeed
    }

    private static let entriesByCategory: [TreinoTipo: [String: [Entry]]] = Dictionary(
        uniqueKeysWithValues: sectionsByCategory.map { category, sections in
            (category, Dictionary(uniqueKeysWithValues: sections.map { section in
                (section, DefaultWorkoutsProvider.defaultsFor(category: category, sectionKey: section).map {
                    Entry(
                        key: defaultKey(for: $0, sectionKey: section, category: category),
                        category: category,
                        seed: $0
                    )
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
        defaultKey(name: seed.name, sectionKey: sectionKey, category: category)
    }

    static func defaultKey(name: String, sectionKey: String, category: TreinoTipo) -> String {
        let slug = name.lowercased().unicodeScalars.map {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789").contains($0)
                ? String($0) : "_"
        }.joined().split(separator: "_").joined(separator: "_")
        return "default_workout.\(category.rawValue).\(sectionKey).\(slug)"
    }

    // Persistence and legacy matching must use the same baseline, regardless of the app locale.
    static func seedText(for key: String) -> String {
        AppLocalization.string(String.LocalizationValue(key), locale: Locale(identifier: "pt-BR"))
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
        var result = template
        let localized = localizedPresentation(
            title: template.title,
            description: template.description,
            blocks: template.blocks ?? [],
            entry: entry,
            locale: locale
        )
        result.title = localized.title
        result.description = localized.description
        result.blocks = template.blocks == nil ? nil : localized.blocks
        return result
    }

    static func presentation(for day: TrainingDayFS, locale: Locale) -> TrainingDayFS {
        guard let entry = entry(for: day) else { return day }
        let localized = localizedPresentation(
            title: day.title,
            description: day.description,
            blocks: day.blocks,
            entry: entry,
            locale: locale
        )
        var result = day
        result.title = localized.title
        result.description = localized.description
        result.blocks = localized.blocks
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
            guard let blocks = template.blocks else { return false }
            return matchesLegacyContent(
                title: template.title,
                description: template.description,
                blocks: blocks,
                seed: entry.seed
            )
        }
    }

    private static func entry(for day: TrainingDayFS) -> Entry? {
        for sections in entriesByCategory.values {
            for entries in sections.values {
                if let entry = entries.first(where: {
                    matchesLegacyContent(
                        title: day.title,
                        description: day.description,
                        blocks: day.blocks,
                        seed: $0.seed
                    )
                }) {
                    return entry
                }
            }
        }
        return nil
    }

    private static func matchesLegacyContent(
        title: String,
        description: String,
        blocks: [BlockFS],
        seed: DefaultWorkoutSeed
    ) -> Bool {
        guard matchesLegacyText(title, seed.name) || matchesLegacyText(title, seed.title),
              matchesLegacyText(description, persistedDescription(for: seed))
                || matchesLegacyText(description, seed.description) else {
            return false
        }
        let originals = seed.blocks.sorted { $0.order < $1.order }
        return blocks.count == originals.count && zip(blocks, originals).allSatisfy {
            matchesLegacyText($0.0.name, $0.1.title)
                && matchesLegacyText($0.0.details, $0.1.text)
        }
    }

    private static func localizedPresentation(
        title: String,
        description: String,
        blocks: [BlockFS],
        entry: Entry,
        locale: Locale
    ) -> (title: String, description: String, blocks: [BlockFS]) {
        let seed = entry.seed
        let localizedTitle: String
        if matchesLegacyText(title, seed.name) {
            let titleComponent = entry.category == .crossfit ? "name" : "title"
            localizedTitle = localized("\(entry.key).\(titleComponent)", fallback: title, locale: locale)
        } else if matchesLegacyText(title, seed.title) {
            localizedTitle = localized("\(entry.key).title", fallback: title, locale: locale)
        } else {
            localizedTitle = title
        }

        let localizedDescription: String
        if matchesLegacyText(description, persistedDescription(for: seed)) {
            localizedDescription = [
                localized("\(entry.key).title", fallback: seed.title, locale: locale),
                localized("\(entry.key).description", fallback: seed.description, locale: locale)
            ].filter { !$0.isEmpty }.joined(separator: "\n")
        } else if matchesLegacyText(description, seed.description) {
            localizedDescription = localized(
                "\(entry.key).description", fallback: description, locale: locale
            )
        } else {
            localizedDescription = description
        }

        let localizedBlocks = blocks.map { block in
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

        return (localizedTitle, localizedDescription, localizedBlocks)
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

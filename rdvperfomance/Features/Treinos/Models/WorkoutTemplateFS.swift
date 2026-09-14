import Foundation
import FirebaseFirestore

struct WorkoutTemplateFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var teacherId: String
    var categoryRaw: String
    var sectionKey: String

    var title: String
    var description: String

    // Para evoluir depois: blocos prontos do dia
    var blocks: [BlockFS]?

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}

extension WorkoutTemplateFS {
    func primaryBlock(for category: TreinoTipo) -> BlockFS? {
        Self.primaryBlock(from: blocks ?? [], for: category)
    }

    func primaryDisplayText(for category: TreinoTipo) -> String {
        Self.primaryDisplayText(
            from: blocks ?? [],
            for: category,
            legacyTitle: title
        )
    }

    func technicalTitle(for category: TreinoTipo) -> String {
        Self.technicalTitle(
            from: blocks ?? [],
            for: category,
            legacyTitle: title
        )
    }

    static func primaryBlock(
        from blocks: [BlockFS],
        for category: TreinoTipo,
        includingContentFallback: Bool = true
    ) -> BlockFS? {
        let expectedName = expectedPrimaryBlockName(for: category)

        if let namedBlock = blocks.first(where: {
            normalizedText($0.name) == normalizedText(expectedName)
        }) {
            return namedBlock
        }

        if let identifiedBlock = blocks.first(where: {
            stableIdentifier($0.id) == stableIdentifier(expectedName)
        }) {
            return identifiedBlock
        }

        if let positionedBlock = originalCreatorPrimaryBlock(in: blocks) {
            return positionedBlock
        }

        return includingContentFallback
            ? blocks.first(where: { !trimmed($0.details).isEmpty })
            : nil
    }

    static func primaryDisplayText(
        from blocks: [BlockFS],
        for category: TreinoTipo,
        legacyTitle: String = ""
    ) -> String {
        if let primaryDetails = primaryBlock(from: blocks, for: category)
            .map({ trimmed($0.details) }),
           !primaryDetails.isEmpty {
            return primaryDetails
        }

        if let firstDetails = blocks.lazy
            .map({ trimmed($0.details) })
            .first(where: { !$0.isEmpty }) {
            return firstDetails
        }

        let legacyTitle = trimmed(legacyTitle)
        if !legacyTitle.isEmpty {
            return legacyTitle
        }

        return fallbackDisplayLabel(for: category)
    }

    static func technicalTitle(
        from blocks: [BlockFS],
        for category: TreinoTipo,
        legacyTitle: String = ""
    ) -> String {
        let displayText = primaryDisplayText(
            from: blocks,
            for: category,
            legacyTitle: legacyTitle
        )

        return firstNonEmptyLine(in: displayText) ?? fallbackDisplayLabel(for: category)
    }

    private static func expectedPrimaryBlockName(for category: TreinoTipo) -> String {
        category == .crossfit ? "WOD" : "Treino"
    }

    private static func fallbackDisplayLabel(for category: TreinoTipo) -> String {
        switch category {
        case .crossfit:
            return "WOD"
        case .academia:
            return "Treino de Academia"
        case .emCasa:
            return "Treino em Casa"
        }
    }

    // The three creator views always start with these surrounding blocks, so index 2 is
    // only trusted when the original layout is still identifiable after a main-block rename.
    private static func originalCreatorPrimaryBlock(in blocks: [BlockFS]) -> BlockFS? {
        guard blocks.count >= 4,
              normalizedText(blocks[0].name) == "aquecimento",
              normalizedText(blocks[1].name) == "tecnica",
              normalizedText(blocks[3].name) == "cargas / movimentos" else {
            return nil
        }

        return blocks[2]
    }

    private static func firstNonEmptyLine(in text: String) -> String? {
        text.components(separatedBy: .newlines)
            .map(trimmed)
            .first(where: { !$0.isEmpty })
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizedText(_ value: String) -> String {
        trimmed(value)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
    }

    private static func stableIdentifier(_ value: String) -> String {
        normalizedText(value)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

import Foundation

enum DefaultWorkoutBlock: Hashable {
    case warmup
    case technique
    case wod
    case workout
    case loadsAndMovements

    var persistedName: String {
        switch self {
        case .warmup: "Aquecimento"
        case .technique: "Técnica"
        case .wod: "WOD"
        case .workout: "Treino"
        case .loadsAndMovements: "Cargas / Movimentos"
        }
    }

    func localizedName(locale: Locale) -> String {
        switch self {
        case .warmup:
            String(localized: "Aquecimento", locale: locale)
        case .technique:
            String(localized: "Técnica", locale: locale)
        case .wod:
            String(localized: "WOD", locale: locale)
        case .workout:
            String(localized: "Treino", locale: locale)
        case .loadsAndMovements:
            String(localized: "Cargas / Movimentos", locale: locale)
        }
    }
}

/// Rascunho de bloco usado nas telas de criação de templates (WOD/Treino)
struct BlockDraft: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var details: String
    private var defaultBlock: DefaultWorkoutBlock?

    init(id: String = UUID().uuidString, name: String, details: String) {
        self.id = id
        self.name = name
        self.details = details
        self.defaultBlock = nil
    }

    init(defaultBlock: DefaultWorkoutBlock, details: String = "") {
        self.id = UUID().uuidString
        self.name = defaultBlock.persistedName
        self.details = details
        self.defaultBlock = defaultBlock
    }

    func displayedName(locale: Locale) -> String {
        (defaultBlock ?? DefaultWorkoutBlock(persistedName: name))?.localizedName(locale: locale) ?? name
    }

    mutating func setDisplayedName(_ name: String) {
        self.name = name
        defaultBlock = nil
    }
}

extension DefaultWorkoutBlock: CaseIterable {
    init?(persistedName: String) {
        guard let block = Self.allCases.first(where: { $0.persistedName == persistedName }) else {
            return nil
        }
        self = block
    }
}

extension BlockFS {
    func displayedName(locale: Locale) -> String {
        DefaultWorkoutBlock(persistedName: name)?.localizedName(locale: locale) ?? name
    }
}

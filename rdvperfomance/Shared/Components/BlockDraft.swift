import Foundation

enum DefaultWorkoutBlock: Hashable {
    case warmup
    case technique
    case wod
    case workout
    case loadsAndMovements
    case newBlock

    var persistedName: String {
        switch self {
        case .warmup: "Aquecimento"
        case .technique: "Técnica"
        case .wod: "WOD"
        case .workout: "Treino"
        case .loadsAndMovements: "Cargas / Movimentos"
        case .newBlock: "Novo bloco"
        }
    }

    func localizedName(locale: Locale) -> String {
        switch self {
        case .warmup:
            AppLocalization.string("workout_block.warmup", locale: locale)
        case .technique:
            AppLocalization.string("workout_block.technique", locale: locale)
        case .wod:
            AppLocalization.string("workout_block.wod", locale: locale)
        case .workout:
            AppLocalization.string("workout_block.workout", locale: locale)
        case .loadsAndMovements:
            AppLocalization.string("workout_block.loads_and_movements", locale: locale)
        case .newBlock:
            AppLocalization.string("ui.new_block", locale: locale)
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

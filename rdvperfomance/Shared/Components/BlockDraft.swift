import Foundation

/// Rascunho de bloco usado nas telas de criação de templates (WOD/Treino)
struct BlockDraft: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var details: String

    init(id: String = UUID().uuidString, name: String, details: String) {
        self.id = id
        self.name = name
        self.details = details
    }
}

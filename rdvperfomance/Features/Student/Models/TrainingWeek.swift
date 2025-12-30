import Foundation

struct TrainingDay: Identifiable, Hashable {
    let id: UUID
    let title: String
    let summary: String

    init(id: UUID = UUID(), title: String, summary: String) {
        self.id = id
        self.title = title
        self.summary = summary
    }
}

struct TrainingWeek: Identifiable, Hashable {
    let id: UUID
    let weekTitle: String // "Semana 1 - Treino A"
    let category: TreinoTipo
    let progress: Double // 0..1
    let days: [TrainingDay]

    init(
        id: UUID = UUID(),
        weekTitle: String,
        category: TreinoTipo,
        progress: Double,
        days: [TrainingDay]
    ) {
        self.id = id
        self.weekTitle = weekTitle
        self.category = category
        self.progress = progress
        self.days = days
    }
}


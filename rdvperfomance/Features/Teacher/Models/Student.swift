import Foundation

struct Student: Identifiable, Hashable {
    let id: UUID
    let name: String
    let program: TreinoTipo
    let periodText: String
    let progress: Double // 0.0 a 1.0

    init(
        id: UUID = UUID(),
        name: String,
        program: TreinoTipo,
        periodText: String,
        progress: Double
    ) {
        self.id = id
        self.name = name
        self.program = program
        self.periodText = periodText
        self.progress = progress
    }
}

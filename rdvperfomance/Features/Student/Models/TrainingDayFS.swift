// TrainingDayFS.swift — Modelos de dia de treino e bloco para uso com Firestore
import Foundation
import FirebaseFirestore

struct TrainingDayFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var dayIndex: Int
    var dayName: String
    var date: Date?

    var title: String
    var description: String

    var blocks: [BlockFS]

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}

// Bloco dentro de um dia (ex.: Aquecimento / Técnica / WOD)
struct BlockFS: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var details: String
}

// Helpers do dia (subtítulo exibido na UI)
extension TrainingDayFS {
    // Retorna texto curto (ex.: "Segunda • Dia 1")
    var subtitleText: String {
        let idx = max(dayIndex, 0) + 1
        if !dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(dayName) • Dia \(idx)"
        }
        return "Dia \(idx)"
    }
}

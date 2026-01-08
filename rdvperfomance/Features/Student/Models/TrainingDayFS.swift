import Foundation
import FirebaseFirestore

// Modelo de dia de treino armazenado no Firestore
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

// Modelo de bloco dentro de um dia de treino
struct BlockFS: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var details: String
}

extension TrainingDayFS {
    // Retorna texto formatado para exibir na UI
    var subtitleText: String {
        let idx = max(dayIndex, 0) + 1
        if !dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(dayName) • Dia \(idx)"
        }
        return "Dia \(idx)"
    }
}

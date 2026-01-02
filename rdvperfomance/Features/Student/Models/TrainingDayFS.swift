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

struct BlockFS: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var details: String
}

extension TrainingDayFS {
    var subtitleText: String {
        let idx = max(dayIndex, 0) + 1
        if !dayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(dayName) • Dia \(idx)"
        }
        return "Dia \(idx)"
    }
}


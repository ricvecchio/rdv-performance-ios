import Foundation
import FirebaseFirestore

// MARK: - TrainingWeekFS (Firestore: training_weeks)
struct TrainingWeekFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var weekTitle: String
    var studentId: String
    var teacherId: String
    var categoryRaw: String

    var startDate: Date?
    var endDate: Date?

    var isPublished: Bool

    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?
}

// MARK: - Helpers
extension TrainingWeekFS {

    var category: TreinoTipo {
        TreinoTipo(rawValue: categoryRaw) ?? .crossfit
    }
}


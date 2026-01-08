import Foundation
import FirebaseFirestore

// Modelo de semana de treino armazenado no Firestore
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

extension TrainingWeekFS {
    // Converte o valor raw para enum de categoria
    var category: TreinoTipo {
        TreinoTipo(rawValue: categoryRaw) ?? .crossfit
    }
}

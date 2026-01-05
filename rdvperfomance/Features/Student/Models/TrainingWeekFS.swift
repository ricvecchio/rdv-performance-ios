// TrainingWeekFS.swift — Modelo de semana de treino armazenado no Firestore
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
// Helper para obter o tipo de treino a partir do rawValue
extension TrainingWeekFS {
    var category: TreinoTipo {
        TreinoTipo(rawValue: categoryRaw) ?? .crossfit
    }
}

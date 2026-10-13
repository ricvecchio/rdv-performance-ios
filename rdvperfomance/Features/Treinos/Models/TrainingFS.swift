import Foundation
import FirebaseFirestore

// Namespace com constantes e modelos de treino no Firestore
enum TrainingFS {

    static let weeksCollection: String = "training_weeks"
    static let daysSubcollection: String = "days"

    // Modelo de semana de treino
    struct Week: Identifiable, Codable, Hashable {

        @DocumentID var id: String?

        var title: String
        var categoryRaw: String
        var teacherId: String
        var startDate: Date
        var endDate: Date
        var isPublished: Bool

        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?
    }

    // Modelo de dia de treino
    struct Day: Identifiable, Codable, Hashable {

        @DocumentID var id: String?

        var dayIndex: Int
        var dayName: String
        var date: Date

        var title: String
        var description: String

        var blocks: [Block]

        @ServerTimestamp var createdAt: Timestamp?
        @ServerTimestamp var updatedAt: Timestamp?

        // Modelo de bloco de exercício
        struct Block: Identifiable, Codable, Hashable {
            var id: String = UUID().uuidString
            var name: String
            var details: String
        }
    }
}

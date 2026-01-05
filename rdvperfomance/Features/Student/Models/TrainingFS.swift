// TrainingFS.swift — Namespace com constantes e modelos relacionados a treinos no Firestore
import Foundation
import FirebaseFirestore

// Namespace único para estruturas de treino
enum TrainingFS {

    static let weeksCollection: String = "training_weeks"
    static let daysSubcollection: String = "days"

    // Estrutura de Week usada em consultas
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

    // Estrutura Day usada em subcoleção de semanas
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

        struct Block: Identifiable, Codable, Hashable {
            var id: String = UUID().uuidString
            var name: String
            var details: String
        }
    }
}

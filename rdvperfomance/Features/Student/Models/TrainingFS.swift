import Foundation
import FirebaseFirestore

// Namespace único (NÃO duplicar em outros arquivos)
enum TrainingFS {

    static let weeksCollection: String = "training_weeks"
    static let daysSubcollection: String = "days"

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


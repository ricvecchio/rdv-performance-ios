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

        init(
            id: String? = nil,
            title: String,
            categoryRaw: String,
            teacherId: String,
            startDate: Date,
            endDate: Date,
            isPublished: Bool = true,
            createdAt: Timestamp? = nil,
            updatedAt: Timestamp? = nil
        ) {
            self.id = id
            self.title = title
            self.categoryRaw = categoryRaw
            self.teacherId = teacherId
            self.startDate = startDate
            self.endDate = endDate
            self.isPublished = isPublished
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}


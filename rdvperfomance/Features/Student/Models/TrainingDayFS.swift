import Foundation
import FirebaseFirestore

extension TrainingFS {

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

        init(
            id: String? = nil,
            dayIndex: Int,
            dayName: String,
            date: Date,
            title: String,
            description: String,
            blocks: [Block] = [],
            createdAt: Timestamp? = nil,
            updatedAt: Timestamp? = nil
        ) {
            self.id = id
            self.dayIndex = dayIndex
            self.dayName = dayName
            self.date = date
            self.title = title
            self.description = description
            self.blocks = blocks
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    struct Block: Identifiable, Codable, Hashable {
        var id: String = UUID().uuidString
        var name: String
        var details: String
    }
}


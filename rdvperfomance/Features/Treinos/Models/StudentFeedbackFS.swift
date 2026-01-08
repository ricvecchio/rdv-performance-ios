import Foundation
import FirebaseFirestore

/// Modelo de feedback entre professor e aluno armazenado no Firestore
struct StudentFeedbackFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var teacherId: String
    var studentId: String
    var categoryRaw: String

    var text: String

    var authorType: String?
    var authorId: String?

    var createdAt: Date?
    var updatedAt: Date?
}

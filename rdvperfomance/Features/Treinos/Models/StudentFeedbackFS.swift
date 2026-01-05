import Foundation
import FirebaseFirestore

// MARK: - student_feedbacks/{feedbackId}
struct StudentFeedbackFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var teacherId: String
    var studentId: String
    var categoryRaw: String

    var text: String

    // Pra evoluir depois (ex.: aluno também criando feedback)
    var authorType: String?
    var authorId: String?

    var createdAt: Date?
    var updatedAt: Date?
}

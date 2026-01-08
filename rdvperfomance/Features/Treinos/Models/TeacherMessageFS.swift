import Foundation
import FirebaseFirestore

/// Modelo de mensagem enviada pelo professor ao aluno no Firestore
struct TeacherMessageFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var teacherId: String
    var studentId: String
    var categoryRaw: String

    var subject: String?
    var body: String

    var createdAt: Date?
    var updatedAt: Date?
}

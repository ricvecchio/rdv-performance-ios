// StudentFeedbackFS.swift — Modelo de feedbacks entre professor e aluno armazenado no Firestore
import Foundation
import FirebaseFirestore

// Documento student_feedbacks/{feedbackId}
struct StudentFeedbackFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?

    var teacherId: String
    var studentId: String
    var categoryRaw: String

    var text: String

    // Autor opcional (para futuras evoluções)
    var authorType: String?
    var authorId: String?

    var createdAt: Date?
    var updatedAt: Date?
}

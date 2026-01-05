// TeacherMessageFS.swift — Modelo de mensagens enviadas pelo professor ao aluno (Firestore)
import Foundation
import FirebaseFirestore

// Documento teacher_messages/{messageId}
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

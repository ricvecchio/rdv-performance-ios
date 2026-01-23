import Foundation
import FirebaseFirestore

/// Modelo de usuário do aplicativo com dados de alunos e professores
struct AppUser: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var userType: String
    var phone: String?
    var focusArea: String?
    var planType: String?

    var cref: String?
    var bio: String?
    var gymName: String?

    var defaultCategory: String?
    var active: Bool?

    var unitName: String?

    // ✅ foto persistida no Firestore (Base64)
    var photoBase64: String?
}

/// Modelo de relação entre professor e aluno com categorias vinculadas
struct TeacherStudentRelation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var teacherId: String
    var studentId: String
    var categories: [String]
}

/// Convite do professor -> aluno (para aparecer como "Convite pendente" na Agenda)
struct TeacherStudentInviteFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var teacherId: String
    var teacherEmail: String
    var studentEmail: String
    var status: String          // "pending" | "accepted" | "declined"
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}

/// Solicitação do aluno -> professor (fila de "Vincular aluno" do professor)
struct TeacherStudentLinkRequestFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var studentId: String
    var studentEmail: String
    var teacherId: String
    var teacherEmail: String
    var status: String          // "pending" | "accepted" | "declined"
    var createdAt: Timestamp?
    var updatedAt: Timestamp?
}


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
}

/// Modelo de relação entre professor e aluno com categorias vinculadas
struct TeacherStudentRelation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var teacherId: String
    var studentId: String
    var categories: [String]
}

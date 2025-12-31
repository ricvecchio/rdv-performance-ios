import Foundation
import FirebaseFirestore

// MARK: - UserFS (documento em /users/{uid})
struct UserFS: Identifiable, Codable, Hashable {

    @DocumentID var id: String?

    var name: String
    var email: String

    /// "STUDENT" | "TRAINER"
    var userType: String   // ✅ ERA userTypeRaw

    /// Categoria padrão do aluno (ex: "crossfit")
    var defaultCategory: String?

    /// Relacionamento simples: aluno aponta para professor (uid do professor)
    var teacherId: String?

    /// Controle simples
    var active: Bool?

    /// Auditoria
    @ServerTimestamp var createdAt: Timestamp?
    @ServerTimestamp var updatedAt: Timestamp?

    init(
        id: String? = nil,
        name: String,
        email: String,
        userType: String,
        defaultCategory: String? = nil,
        teacherId: String? = nil,
        active: Bool? = nil,
        createdAt: Timestamp? = nil,
        updatedAt: Timestamp? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.userType = userType
        self.defaultCategory = defaultCategory
        self.teacherId = teacherId
        self.active = active
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension UserFS {
    static let collectionName = "users"
}


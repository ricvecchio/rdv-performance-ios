// FirestoreModels.swift — Modelos leves usados para mapear documentos do Firestore
import Foundation
import FirebaseFirestore

// User (users/{uid})
struct AppUser: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // uid
    var name: String
    var email: String
    var userType: String
    var phone: String?
    var focusArea: String?
    var planType: String?

    // TRAINER
    var cref: String?
    var bio: String?
    var gymName: String?

    // STUDENT
    var defaultCategory: String?
    var active: Bool?

    // Unidade associada ao usuário
    var unitName: String?
}

// Relação teacher_students (doc com categorias vinculadas)
struct TeacherStudentRelation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var teacherId: String
    var studentId: String
    var categories: [String]
}

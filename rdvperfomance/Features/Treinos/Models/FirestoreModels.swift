import Foundation
import FirebaseFirestore

// MARK: - User (users/{uid})
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
}

// MARK: - teacher_students
struct TeacherStudentRelation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var teacherId: String
    var studentId: String
    var categories: [String]
}

// MARK: - training_weeks
struct TrainingWeekFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var studentId: String
    var teacherId: String
    var category: String
    var weekTitle: String
    var progress: Double
    var status: String
}

// MARK: - training_weeks/{weekId}/days
struct TrainingDayFS: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var order: Int
    var title: String
    var summary: String
    var details: String
    var done: Bool
}


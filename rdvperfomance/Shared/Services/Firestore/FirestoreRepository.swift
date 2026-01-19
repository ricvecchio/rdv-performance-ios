import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Compositor principal que agrega todos os repositórios especializados
final class FirestoreRepository {
    static let shared = FirestoreRepository()
    
    // Repositórios especializados
    private let userRepository = UserRepository()
    private let trainingRepository = TrainingRepository()
    private let progressRepository = ProgressRepository()
    private let messageRepository = MessageRepository()
    private let feedbackRepository = FeedbackRepository()
    private let workoutTemplateRepository = WorkoutTemplateRepository()
    
    private init() {}
    
    // MARK: - User Operations
    func getUser(uid: String) async throws -> AppUser? {
        try await userRepository.getUser(uid: uid)
    }
    
    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {
        try await userRepository.getStudentsForTeacher(teacherId: teacherId, category: category)
    }
    
    func unlinkStudentFromTeacher(teacherId: String, studentId: String, category: String) async throws {
        try await userRepository.unlinkStudentFromTeacher(
            teacherId: teacherId,
            studentId: studentId,
            category: category
        )
    }
    
    func upsertUserProfile(uid: String, form: RegisterFormDTO) async throws {
        try await userRepository.upsertUserProfile(uid: uid, form: form)
    }
    
    func setUserPhotoBase64(uid: String, photoBase64: String) async throws {
        try await userRepository.setUserPhotoBase64(uid: uid, photoBase64: photoBase64)
    }
    
    func clearUserPhotoBase64(uid: String) async throws {
        try await userRepository.clearUserPhotoBase64(uid: uid)
    }
    
    func setStudentUnitName(uid: String, unitName: String?) async throws {
        try await userRepository.setStudentUnitName(uid: uid, unitName: unitName)
    }
    
    // MARK: - Training Operations
    func getWeeksForStudent(studentId: String, onlyPublished: Bool = true) async throws -> [TrainingWeekFS] {
        try

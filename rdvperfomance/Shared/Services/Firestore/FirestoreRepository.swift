import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreRepository {

    nonisolated static let shared = FirestoreRepository()

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

    // MARK: - Link / Invite / Request (Aluno <-> Professor)

    func getTeacherByEmail(email: String) async throws -> AppUser? {
        try await userRepository.getTeacherByEmail(email: email)
    }

    func getActiveTeacherRelationForStudent(studentId: String) async throws -> TeacherStudentRelation? {
        try await userRepository.getActiveTeacherRelationForStudent(studentId: studentId)
    }

    func getPendingInviteForStudentEmail(studentEmail: String) async throws -> TeacherStudentInviteFS? {
        try await userRepository.getPendingInviteForStudentEmail(studentEmail: studentEmail)
    }

    func createLinkRequest(
        studentId: String,
        studentEmail: String,
        teacherId: String,
        teacherEmail: String
    ) async throws {
        try await userRepository.createLinkRequest(
            studentId: studentId,
            studentEmail: studentEmail,
            teacherId: teacherId,
            teacherEmail: teacherEmail
        )
    }

    func acceptInvite(invite: TeacherStudentInviteFS, studentId: String) async throws {
        try await userRepository.acceptInvite(invite: invite, studentId: studentId)
    }

    func acceptInvite(invite: TeacherStudentInviteFS, studentId: String, studentUser: AppUser?) async throws {
        _ = studentUser
        try await userRepository.acceptInvite(invite: invite, studentId: studentId)
    }

    func declineInvite(invite: TeacherStudentInviteFS) async throws {
        try await userRepository.declineInvite(invite: invite)
    }

    // MARK: - Convites enviados pelo professor

    func getInvitesSentByTeacher(
        teacherId: String,
        status: String?,
        limit: Int
    ) async throws -> [TeacherStudentInviteFS] {
        try await userRepository.getInvitesSentByTeacher(
            teacherId: teacherId,
            status: status,
            limit: limit
        )
    }

    func createTeacherInviteByEmail(
        teacherId: String,
        teacherEmail: String,
        studentEmail: String
    ) async throws -> String {
        try await userRepository.createTeacherInviteByEmail(
            teacherId: teacherId,
            teacherEmail: teacherEmail,
            studentEmail: studentEmail
        )
    }

    func cancelTeacherInvite(inviteId: String) async throws {
        try await userRepository.cancelTeacherInvite(inviteId: inviteId)
    }

    // MARK: - Requests pendentes (Professor) + Aprovação/Vínculo

    func getPendingLinkRequestsForTeacher(teacherId: String) async throws -> [TeacherStudentLinkRequestFS] {
        try await userRepository.getPendingLinkRequestsForTeacher(teacherId: teacherId)
    }

    func approveLinkRequestAndLinkStudent(
        teacherId: String,
        requestId: String,
        studentId: String,
        category: String
    ) async throws {
        try await userRepository.approveLinkRequestAndLinkStudent(
            teacherId: teacherId,
            requestId: requestId,
            studentId: studentId,
            category: category
        )
    }

    // MARK: - APIs usadas por StudentLinksViewModel (aliases)

    func getTeacherLinksForStudent(studentId: String) async throws -> [TeacherStudentRelation] {
        try await userRepository.getTeacherLinksForStudent(studentId: studentId)
    }

    func getInvitesForStudent(studentEmail: String) async throws -> [TeacherStudentInviteFS] {
        try await userRepository.getInvitesForStudent(studentEmail: studentEmail)
    }

    func getRequestsForStudent(studentId: String) async throws -> [TeacherStudentLinkRequestFS] {
        try await userRepository.getRequestsForStudent(studentId: studentId)
    }

    func createStudentLinkRequest(
        studentId: String,
        studentEmail: String,
        teacherId: String,
        teacherEmail: String
    ) async throws {
        try await userRepository.createLinkRequest(
            studentId: studentId,
            studentEmail: studentEmail,
            teacherId: teacherId,
            teacherEmail: teacherEmail
        )
    }

    func acceptStudentInvite(inviteId: String, studentId: String) async throws {
        try await userRepository.acceptStudentInvite(inviteId: inviteId, studentId: studentId)
    }

    // MARK: - Training Operations

    func getWeeksForStudent(studentId: String, onlyPublished: Bool = true) async throws -> [TrainingWeekFS] {
        try await trainingRepository.getWeeksForStudent(studentId: studentId, onlyPublished: onlyPublished)
    }

    func getDaysForWeek(weekId: String) async throws -> [TrainingDayFS] {
        try await trainingRepository.getDaysForWeek(weekId: weekId)
    }

    func getDays(for week: TrainingWeekFS) async throws -> [TrainingDayFS] {
        try await trainingRepository.getDays(for: week)
    }

    func createWeekForStudent(
        studentId: String,
        teacherId: String,
        title: String,
        categoryRaw: String,
        startDate: Date,
        endDate: Date,
        isPublished: Bool = true
    ) async throws -> String {
        try await trainingRepository.createWeekForStudent(
            studentId: studentId,
            teacherId: teacherId,
            title: title,
            categoryRaw: categoryRaw,
            startDate: startDate,
            endDate: endDate,
            isPublished: isPublished
        )
    }

    func upsertDay(
        weekId: String,
        dayId: String? = nil,
        dayIndex: Int,
        dayName: String,
        date: Date,
        title: String,
        description: String,
        blocks: [BlockFS] = []
    ) async throws -> String {
        try await trainingRepository.upsertDay(
            weekId: weekId,
            dayId: dayId,
            dayIndex: dayIndex,
            dayName: dayName,
            date: date,
            title: title,
            description: description,
            blocks: blocks
        )
    }

    func publishWeek(weekId: String, isPublished: Bool) async throws {
        try await trainingRepository.publishWeek(weekId: weekId, isPublished: isPublished)
    }

    func updateWeekTitle(weekId: String, newTitle: String) async throws {
        try await trainingRepository.updateWeekTitle(weekId: weekId, newTitle: newTitle)
    }

    func updateWeekDateRangeFromDays(weekId: String) async throws {
        try await trainingRepository.updateWeekDateRangeFromDays(weekId: weekId)
    }

    func deleteTrainingWeekCascade(weekId: String) async throws {
        try await trainingRepository.deleteTrainingWeekCascade(weekId: weekId)
    }

    func deleteTrainingDay(weekId: String, dayId: String) async throws {
        try await trainingRepository.deleteTrainingDay(weekId: weekId, dayId: dayId)
    }

    func hasAnyWeeksForStudent(studentId: String) async throws -> Bool {
        try await trainingRepository.hasAnyWeeksForStudent(studentId: studentId)
    }

    // MARK: - Progress Operations

    func getDayStatusMap(weekId: String, studentId: String) async throws -> [String: Bool] {
        try await progressRepository.getDayStatusMap(weekId: weekId, studentId: studentId)
    }

    func setDayCompleted(weekId: String, studentId: String, dayId: String, completed: Bool) async throws {
        try await progressRepository.setDayCompleted(
            weekId: weekId,
            studentId: studentId,
            dayId: dayId,
            completed: completed
        )
    }

    func getWeekProgress(weekId: String, studentId: String) async throws -> (completed: Int, total: Int) {
        try await progressRepository.getWeekProgress(weekId: weekId, studentId: studentId)
    }

    func getStudentOverallProgress(studentId: String) async throws -> (percent: Int, completed: Int, total: Int) {
        try await progressRepository.getStudentOverallProgress(studentId: studentId)
    }

    // MARK: - Message Operations

    func createTeacherMessage(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        subject: String?,
        body: String
    ) async throws -> String {
        try await messageRepository.createTeacherMessage(
            teacherId: teacherId,
            studentId: studentId,
            categoryRaw: categoryRaw,
            subject: subject,
            body: body
        )
    }

    func getTeacherMessages(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [TeacherMessageFS] {
        try await messageRepository.getTeacherMessages(
            teacherId: teacherId,
            studentId: studentId,
            categoryRaw: categoryRaw,
            limit: limit
        )
    }

    func getMessagesForStudent(
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [TeacherMessageFS] {
        try await messageRepository.getMessagesForStudent(
            studentId: studentId,
            categoryRaw: categoryRaw,
            limit: limit
        )
    }

    // MARK: - Feedback Operations

    func createStudentFeedback(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        text: String
    ) async throws -> String {
        try await feedbackRepository.createStudentFeedback(
            teacherId: teacherId,
            studentId: studentId,
            categoryRaw: categoryRaw,
            text: text
        )
    }

    func getStudentFeedbacks(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [StudentFeedbackFS] {
        try await feedbackRepository.getStudentFeedbacks(
            teacherId: teacherId,
            studentId: studentId,
            categoryRaw: categoryRaw,
            limit: limit
        )
    }

    func getFeedbacksForStudent(
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [StudentFeedbackFS] {
        try await feedbackRepository.getFeedbacksForStudent(
            studentId: studentId,
            categoryRaw: categoryRaw,
            limit: limit
        )
    }

    // MARK: - Workout Template Operations

    func createWorkoutTemplate(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        title: String,
        description: String,
        blocks: [BlockFS] = []
    ) async throws -> String {
        try await workoutTemplateRepository.createWorkoutTemplate(
            teacherId: teacherId,
            categoryRaw: categoryRaw,
            sectionKey: sectionKey,
            title: title,
            description: description,
            blocks: blocks
        )
    }

    func getWorkoutTemplates(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        limit: Int = 100
    ) async throws -> [WorkoutTemplateFS] {
        try await workoutTemplateRepository.getWorkoutTemplates(
            teacherId: teacherId,
            categoryRaw: categoryRaw,
            sectionKey: sectionKey,
            limit: limit
        )
    }

    func updateWorkoutTemplateBlocks(
        templateId: String,
        blocks: [BlockFS]
    ) async throws {
        try await workoutTemplateRepository.updateWorkoutTemplateBlocks(
            templateId: templateId,
            blocks: blocks
        )
    }

    func deleteWorkoutTemplate(templateId: String) async throws {
        try await workoutTemplateRepository.deleteWorkoutTemplate(templateId: templateId)
    }
}


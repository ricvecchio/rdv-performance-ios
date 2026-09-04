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
    private let studentPersonalRecordsRepository = StudentPersonalRecordsRepository()

    private init() {}

    // MARK: - User Operations

    func getUser(uid: String) async throws -> AppUser? {
        try await userRepository.getUser(uid: uid)
    }

    func getUsers(byIds ids: [String]) async throws -> [String: AppUser] {
        try await userRepository.getUsers(byIds: ids)
    }

    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {
        try await userRepository.getStudentsForTeacher(teacherId: teacherId, category: category)
    }

    /// Alunos do professor já agrupados por categoria canônica, com o mínimo de leituras
    /// no Firestore (1 query em teacher_students + leitura em lote de /users).
    func getStudentsGroupedByTeacher(teacherId: String) async throws -> [TreinoTipo: [AppUser]] {
        try await userRepository.getStudentsGroupedByTeacher(teacherId: teacherId)
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

    func updateUserProfile(
        uid: String,
        phone: String?,
        cref: String?,
        bio: String?,
        focusArea: String
    ) async throws {
        try await userRepository.updateUserProfile(
            uid: uid,
            phone: phone,
            cref: cref,
            bio: bio,
            focusArea: focusArea
        )
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

    // MARK: - Profile Notification State

    func getProfileNotificationState(uid: String) async throws -> ProfileNotificationState {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        let reference = Firestore.firestore()
            .collection("users")
            .document(cleanUid)
            .collection("notification_state")
            .document("profile")
        let snapshot = try await reference.getDocument()
        let data = snapshot.data() ?? [:]
        let now = Date()
        let messages = Self.notificationTimestamps(from: data["messagesLastSeenByCategory"])
        let feedbacks = Self.notificationTimestamps(from: data["feedbacksLastSeenByCategory"])
        let teacherActivities = data["teacherActivitiesLastSeen"] as? Timestamp
        let containsFutureTimestamp = messages.values.contains { $0.dateValue() > now }
            || feedbacks.values.contains { $0.dateValue() > now }
            || (teacherActivities?.dateValue() ?? .distantPast) > now

        if containsFutureTimestamp {
            try? await repairFutureProfileNotificationState(
                at: reference,
                notAfter: now
            )
        }

        return ProfileNotificationState(
            messagesLastSeenByCategory: notificationDates(from: messages, notAfter: now),
            feedbacksLastSeenByCategory: notificationDates(from: feedbacks, notAfter: now),
            teacherActivitiesLastSeen: teacherActivities.map { min($0.dateValue(), now) }
        )
    }

    func mergeProfileNotificationState(
        uid: String,
        messagesLastSeenByCategory: [String: Date] = [:],
        feedbacksLastSeenByCategory: [String: Date] = [:],
        teacherActivitiesLastSeen: Date? = nil
    ) async throws {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        let messageDates = normalizedNotificationDates(messagesLastSeenByCategory)
        let feedbackDates = normalizedNotificationDates(feedbacksLastSeenByCategory)
        guard !messageDates.isEmpty || !feedbackDates.isEmpty || teacherActivitiesLastSeen != nil else { return }
        let now = Date()

        let reference = Firestore.firestore()
            .collection("users")
            .document(cleanUid)
            .collection("notification_state")
            .document("profile")

        let result = try await Firestore.firestore().runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(reference)
                let data = snapshot.data() ?? [:]
                let storedMessages = Self.notificationTimestamps(from: data["messagesLastSeenByCategory"])
                let storedFeedbacks = Self.notificationTimestamps(from: data["feedbacksLastSeenByCategory"])
                let storedTeacherActivities = data["teacherActivitiesLastSeen"] as? Timestamp
                var messageCategoriesToUpdate = Set(
                    storedMessages.compactMap { $0.value.dateValue() > now ? $0.key : nil }
                )
                var feedbackCategoriesToUpdate = Set(
                    storedFeedbacks.compactMap { $0.value.dateValue() > now ? $0.key : nil }
                )
                var shouldUpdateTeacherActivities =
                    (storedTeacherActivities?.dateValue() ?? .distantPast) > now

                for (category, date) in messageDates {
                    let requestedDate = min(date, now)
                    if (storedMessages[category]?.dateValue() ?? .distantPast) < requestedDate {
                        messageCategoriesToUpdate.insert(category)
                    }
                }

                for (category, date) in feedbackDates {
                    let requestedDate = min(date, now)
                    if (storedFeedbacks[category]?.dateValue() ?? .distantPast) < requestedDate {
                        feedbackCategoriesToUpdate.insert(category)
                    }
                }

                if let teacherActivitiesLastSeen {
                    let requestedDate = min(teacherActivitiesLastSeen, now)
                    if (storedTeacherActivities?.dateValue() ?? .distantPast) < requestedDate {
                        shouldUpdateTeacherActivities = true
                    }
                }

                guard !messageCategoriesToUpdate.isEmpty
                    || !feedbackCategoriesToUpdate.isEmpty
                    || shouldUpdateTeacherActivities else {
                    return true
                }

                var payload: [String: Any] = [:]
                // Persist advancing markers with Firestore time, never the device clock.
                if !messageCategoriesToUpdate.isEmpty {
                    var messages: [String: Any] = storedMessages.reduce(into: [:]) {
                        $0[$1.key] = $1.value
                    }
                    for category in messageCategoriesToUpdate {
                        messages[category] = FieldValue.serverTimestamp()
                    }
                    payload["messagesLastSeenByCategory"] = messages
                }
                if !feedbackCategoriesToUpdate.isEmpty {
                    var feedbacks: [String: Any] = storedFeedbacks.reduce(into: [:]) {
                        $0[$1.key] = $1.value
                    }
                    for category in feedbackCategoriesToUpdate {
                        feedbacks[category] = FieldValue.serverTimestamp()
                    }
                    payload["feedbacksLastSeenByCategory"] = feedbacks
                }
                if shouldUpdateTeacherActivities {
                    payload["teacherActivitiesLastSeen"] = FieldValue.serverTimestamp()
                }

                if snapshot.exists {
                    transaction.updateData(payload, forDocument: reference)
                } else {
                    transaction.setData(payload, forDocument: reference)
                }
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard result as? Bool == true else {
            throw FirestoreRepositoryError.writeFailed
        }
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
        studentEmail: String,
        categoryRaw: String? = nil
    ) async throws -> String {
        try await userRepository.createTeacherInviteByEmail(
            teacherId: teacherId,
            teacherEmail: teacherEmail,
            studentEmail: studentEmail,
            categoryRaw: categoryRaw
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

    func declineLinkRequest(requestId: String) async throws {
        try await userRepository.declineLinkRequest(requestId: requestId)
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

    func cancelLinkRequest(requestId: String) async throws {
        try await userRepository.cancelLinkRequest(requestId: requestId)
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

    // MARK: - Student Personal Records

    func getStudentPersonalRecords(uid: String) async throws -> StudentPersonalRecordsCloudDocument? {
        try await studentPersonalRecordsRepository.getStudentPersonalRecords(uid: uid)
    }

    func saveStudentPersonalRecords(
        uid: String,
        payloads: [String: Data],
        customTombstones: [String: [String]]
    ) async throws -> StudentPersonalRecordsCloudDocument {
        try await studentPersonalRecordsRepository.saveStudentPersonalRecords(
            uid: uid,
            payloads: payloads,
            customTombstones: customTombstones
        )
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

    func createWorkoutTemplatesBatch(
        teacherId: String,
        categoryRaw: String,
        sectionKey: String,
        items: [(title: String, description: String, blocks: [BlockFS])]
    ) async throws {
        try await workoutTemplateRepository.createWorkoutTemplatesBatch(
            teacherId: teacherId,
            categoryRaw: categoryRaw,
            sectionKey: sectionKey,
            items: items
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

    private func repairFutureProfileNotificationState(
        at reference: DocumentReference,
        notAfter date: Date
    ) async throws {
        let result = try await Firestore.firestore().runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(reference)
                let data = snapshot.data() ?? [:]
                let storedMessages = Self.notificationTimestamps(from: data["messagesLastSeenByCategory"])
                let storedFeedbacks = Self.notificationTimestamps(from: data["feedbacksLastSeenByCategory"])
                let storedTeacherActivities = data["teacherActivitiesLastSeen"] as? Timestamp
                let futureMessageCategories = storedMessages.compactMap {
                    $0.value.dateValue() > date ? $0.key : nil
                }
                let futureFeedbackCategories = storedFeedbacks.compactMap {
                    $0.value.dateValue() > date ? $0.key : nil
                }
                let hasFutureTeacherActivities =
                    (storedTeacherActivities?.dateValue() ?? .distantPast) > date

                guard !futureMessageCategories.isEmpty
                    || !futureFeedbackCategories.isEmpty
                    || hasFutureTeacherActivities else {
                    return true
                }

                var payload: [String: Any] = [:]
                if !futureMessageCategories.isEmpty {
                    var messages: [String: Any] = storedMessages.reduce(into: [:]) {
                        $0[$1.key] = $1.value
                    }
                    for category in futureMessageCategories {
                        messages[category] = FieldValue.serverTimestamp()
                    }
                    payload["messagesLastSeenByCategory"] = messages
                }
                if !futureFeedbackCategories.isEmpty {
                    var feedbacks: [String: Any] = storedFeedbacks.reduce(into: [:]) {
                        $0[$1.key] = $1.value
                    }
                    for category in futureFeedbackCategories {
                        feedbacks[category] = FieldValue.serverTimestamp()
                    }
                    payload["feedbacksLastSeenByCategory"] = feedbacks
                }
                if hasFutureTeacherActivities {
                    payload["teacherActivitiesLastSeen"] = FieldValue.serverTimestamp()
                }

                transaction.updateData(payload, forDocument: reference)
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        guard result as? Bool == true else {
            throw FirestoreRepositoryError.writeFailed
        }
    }

    private func notificationDates(
        from timestamps: [String: Timestamp],
        notAfter date: Date
    ) -> [String: Date] {
        timestamps.mapValues { min($0.dateValue(), date) }
    }

    private static func notificationTimestamps(from value: Any?) -> [String: Timestamp] {
        guard let values = value as? [String: Any] else { return [:] }

        return values.reduce(into: [:]) { result, item in
            let category = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !category.isEmpty, let timestamp = item.value as? Timestamp else { return }
            result[category] = timestamp
        }
    }

    private func normalizedNotificationDates(_ values: [String: Date]) -> [String: Date] {
        values.reduce(into: [:]) { result, item in
            let category = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !category.isEmpty else { return }
            result[category] = max(result[category] ?? .distantPast, item.value)
        }
    }
}

struct ProfileNotificationState: Sendable {
    let messagesLastSeenByCategory: [String: Date]
    let feedbacksLastSeenByCategory: [String: Date]
    let teacherActivitiesLastSeen: Date?
}

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreRepository {

    static let shared = FirestoreRepository()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Errors
    enum RepositoryError: LocalizedError {
        case missingWeekId
        case missingUserId
        case missingStudentId
        case missingTeacherId
        case invalidData
        case writeFailed
        case notFound

        var errorDescription: String? {
            switch self {
            case .missingWeekId:
                return "Não foi possível carregar/salvar: weekId está vazio ou nulo."
            case .missingUserId:
                return "Não foi possível identificar o usuário (uid vazio)."
            case .missingStudentId:
                return "Não foi possível identificar o aluno (studentId vazio)."
            case .missingTeacherId:
                return "Não foi possível identificar o professor (teacherId vazio)."
            case .invalidData:
                return "Dados inválidos para operação no Firestore."
            case .writeFailed:
                return "Não foi possível salvar os dados no Firestore."
            case .notFound:
                return "Registro não encontrado no Firestore."
            }
        }
    }

    // MARK: - Helpers
    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - users/{uid}
    func getUser(uid: String) async throws -> AppUser? {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw RepositoryError.missingUserId }

        let snap = try await db.collection("users").document(cleanUid).getDocument()
        guard snap.exists else { return nil }

        return try snap.data(as: AppUser.self)
    }

    // MARK: - teacher_students (teacherId + categoria)
    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {

        let cleanTeacherId = clean(teacherId)
        guard !cleanTeacherId.isEmpty else { throw RepositoryError.missingTeacherId }

        let relSnap = try await db.collection("teacher_students")
            .whereField("teacherId", isEqualTo: cleanTeacherId)
            .whereField("categories", arrayContains: category)
            .getDocuments()

        let relations = try relSnap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }

        guard !relations.isEmpty else { return [] }

        let studentIds = relations.map { $0.studentId }

        let tasks: [Task<AppUser?, Never>] = studentIds.map { sid in
            Task {
                do {
                    let snap = try await self.db.collection("users").document(sid).getDocument()
                    guard snap.exists else { return nil }
                    return try snap.data(as: AppUser.self)
                } catch {
                    return nil
                }
            }
        }

        var students: [AppUser] = []
        students.reserveCapacity(tasks.count)

        for task in tasks {
            if let u = await task.value {
                students.append(u)
            }
        }

        return students.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: - training_weeks por aluno (LEITURA)
    func getWeeksForStudent(studentId: String, onlyPublished: Bool = true) async throws -> [TrainingWeekFS] {

        let cleanStudentId = clean(studentId)
        guard !cleanStudentId.isEmpty else { throw RepositoryError.missingStudentId }

        var query: Query = db.collection(TrainingFS.weeksCollection)
            .whereField("studentId", isEqualTo: cleanStudentId)

        if onlyPublished {
            query = query.whereField("isPublished", isEqualTo: true)
        }

        let snap: QuerySnapshot
        do {
            snap = try await query.order(by: "createdAt", descending: false).getDocuments()
        } catch {
            snap = try await query.getDocuments()
        }

        let weeks = try snap.documents.compactMap { try $0.data(as: TrainingWeekFS.self) }

        return weeks.sorted { a, b in
            a.weekTitle.localizedCaseInsensitiveCompare(b.weekTitle) == .orderedAscending
        }
    }

    // MARK: - days subcollection (LEITURA)
    func getDaysForWeek(weekId: String) async throws -> [TrainingDayFS] {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let snap = try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.daysSubcollection)
            .order(by: "dayIndex")
            .getDocuments()

        return try snap.documents.compactMap { try $0.data(as: TrainingDayFS.self) }
    }

    // MARK: - Helper seguro
    func getDays(for week: TrainingWeekFS) async throws -> [TrainingDayFS] {
        guard let weekId = week.id.map(clean(_:)), !weekId.isEmpty else {
            throw RepositoryError.missingWeekId
        }
        return try await getDaysForWeek(weekId: weekId)
    }

    // ============================================================
    // MARK: - ESCRITA (Trainer posta treino para aluno) - MVP
    // ============================================================

    func createWeekForStudent(
        studentId: String,
        teacherId: String,
        title: String,
        categoryRaw: String,
        startDate: Date,
        endDate: Date,
        isPublished: Bool = true
    ) async throws -> String {

        let cleanStudentId = clean(studentId)
        let cleanTeacherId = clean(teacherId)

        guard !cleanStudentId.isEmpty else { throw RepositoryError.missingStudentId }
        guard !cleanTeacherId.isEmpty else { throw RepositoryError.missingTeacherId }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw RepositoryError.invalidData }

        let payload: [String: Any] = [
            "studentId": cleanStudentId,
            "teacherId": cleanTeacherId,
            "title": title,
            "weekTitle": title,
            "categoryRaw": categoryRaw,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "isPublished": isPublished,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        let ref = db.collection(TrainingFS.weeksCollection).document()
        try await ref.setData(payload, merge: true)

        return ref.documentID
    }

    /// ✅ Recalcula startDate/endDate da semana a partir dos dias cadastrados
    func updateWeekDateRangeFromDays(weekId: String) async throws {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let days = try await getDaysForWeek(weekId: cleanWeekId)
        let dates = days.compactMap { $0.date }

        guard let minDate = dates.min(), let maxDate = dates.max() else {
            // Sem dias => não altera a semana
            return
        }

        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "startDate": Timestamp(date: minDate),
                    "endDate": Timestamp(date: maxDate),
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    /// (Opcional) Buscar dia por índice — útil para evoluções
    func getDayForWeekByIndex(weekId: String, dayIndex: Int) async throws -> TrainingDayFS? {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let snap = try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.daysSubcollection)
            .whereField("dayIndex", isEqualTo: dayIndex)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snap.documents.first else { return nil }
        return try doc.data(as: TrainingDayFS.self)
    }

    /// Cria/atualiza um dia dentro da semana (subcoleção days)
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

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw RepositoryError.invalidData }

        let ref: DocumentReference
        if let dayId, !clean(dayId).isEmpty {
            ref = db.collection(TrainingFS.weeksCollection)
                .document(cleanWeekId)
                .collection(TrainingFS.daysSubcollection)
                .document(clean(dayId))
        } else {
            ref = db.collection(TrainingFS.weeksCollection)
                .document(cleanWeekId)
                .collection(TrainingFS.daysSubcollection)
                .document()
        }

        let payload: [String: Any] = [
            "dayIndex": dayIndex,
            "dayName": dayName,
            "date": Timestamp(date: date),
            "title": title,
            "description": description,
            "blocks": blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] },
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await ref.setData(payload, merge: true)

        // ✅ Atualiza updatedAt da semana
        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)

        // ✅ NOVO: Recalcula start/end da semana conforme os dias existentes
        try await updateWeekDateRangeFromDays(weekId: cleanWeekId)

        return ref.documentID
    }

    func publishWeek(weekId: String, isPublished: Bool) async throws {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "isPublished": isPublished,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - users/{uid} (ESCRITA)
    func upsertUserProfile(uid: String, form: RegisterFormDTO) async throws {

        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw RepositoryError.missingUserId }

        let userTypeRaw = form.userType.rawValue
        let payload: [String: Any] = [
            "name": form.name,
            "email": form.email,
            "userType": userTypeRaw,
            "phone": form.phone as Any,
            "focusArea": form.focusArea,
            "planType": form.planType,
            "cref": form.cref as Any,
            "bio": form.bio as Any,
            "gymName": form.gymName as Any,
            "defaultCategory": form.defaultCategory as Any,
            "active": form.active as Any
        ]

        try await db.collection("users")
            .document(cleanUid)
            .setData(payload, merge: true)
    }
}


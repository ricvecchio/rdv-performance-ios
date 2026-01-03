import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirestoreRepository
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

    // MARK: - users/{uid} (LEITURA)
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

        // ✅ TeacherStudentRelation já existe no seu projeto (NÃO redeclarar aqui)
        let relations = try relSnap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }

        guard !relations.isEmpty else { return [] }

        let studentIds = relations.map { $0.studentId }

        // Busca paralela dos perfis
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

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw RepositoryError.invalidData }

        let payload: [String: Any] = [
            "studentId": cleanStudentId,
            "teacherId": cleanTeacherId,
            "title": cleanTitle,       // compatibilidade
            "weekTitle": cleanTitle,   // usado no app
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
            "title": cleanTitle,
            "description": description,
            "blocks": blocks.map { ["id": $0.id, "name": $0.name, "details": $0.details] },
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await ref.setData(payload, merge: true)

        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(["updatedAt": FieldValue.serverTimestamp()], merge: true)

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

    // MARK: - Atualizar título da semana
    func updateWeekTitle(weekId: String, newTitle: String) async throws {
        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let titleTrim = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrim.isEmpty else { throw RepositoryError.invalidData }

        try await db.collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .setData(
                [
                    "weekTitle": titleTrim,
                    "title": titleTrim, // compatibilidade
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - ✅ Atualizar startDate/endDate da semana baseado nos days
    func updateWeekDateRangeFromDays(weekId: String) async throws {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let daysSnap = try await db
            .collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.daysSubcollection)
            .getDocuments()

        guard !daysSnap.documents.isEmpty else { return }

        var dates: [Date] = []
        dates.reserveCapacity(daysSnap.documents.count)

        for doc in daysSnap.documents {
            let data = doc.data()

            if let ts = data["date"] as? Timestamp {
                dates.append(ts.dateValue())
            } else if let d = data["date"] as? Date {
                dates.append(d)
            }
        }

        guard let minDate = dates.min(), let maxDate = dates.max() else { return }

        try await db
            .collection(TrainingFS.weeksCollection)
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

    // MARK: - users/{uid} (ESCRITA)
    func upsertUserProfile(uid: String, form: RegisterFormDTO) async throws {

        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw RepositoryError.missingUserId }

        let payload: [String: Any] = [
            "name": form.name,
            "email": form.email,
            "userType": form.userType.rawValue,
            "phone": form.phone as Any,

            "focusArea": form.focusArea,
            "planType": form.planType,

            // TRAINER
            "cref": form.cref as Any,
            "bio": form.bio as Any,
            "gymName": form.gymName as Any,

            // STUDENT
            "defaultCategory": form.defaultCategory as Any,
            "active": form.active as Any,

            "updatedAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("users")
            .document(cleanUid)
            .setData(payload, merge: true)
    }
}

// ============================================================
// MARK: - Progress / Status (Aluno marca concluído)
// ============================================================

private extension TrainingFS {
    static let statusSubcollection: String = "day_status"
}

extension FirestoreRepository {

    /// Retorna mapa: dayId -> completed
    func getDayStatusMap(weekId: String) async throws -> [String: Bool] {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let snap = try await db
            .collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.statusSubcollection)
            .getDocuments()

        var map: [String: Bool] = [:]
        map.reserveCapacity(snap.documents.count)

        for doc in snap.documents {
            let data = doc.data()
            let completed = (data["completed"] as? Bool) ?? false
            map[doc.documentID] = completed
        }

        return map
    }

    /// Marca/desmarca um dia como concluído (docId = dayId)
    func setDayCompleted(weekId: String, dayId: String, completed: Bool) async throws {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let cleanDayId = clean(dayId)
        guard !cleanDayId.isEmpty else { throw RepositoryError.invalidData }

        let ref = db
            .collection(TrainingFS.weeksCollection)
            .document(cleanWeekId)
            .collection(TrainingFS.statusSubcollection)
            .document(cleanDayId)

        try await ref.setData(
            [
                "completed": completed,
                "updatedAt": FieldValue.serverTimestamp()
            ],
            merge: true
        )
    }

    /// Progresso de uma semana: total de dias x concluídos
    func getWeekProgress(weekId: String) async throws -> (completed: Int, total: Int) {

        let cleanWeekId = clean(weekId)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        async let days = getDaysForWeek(weekId: cleanWeekId)
        async let statusMap = getDayStatusMap(weekId: cleanWeekId)

        let (daysResult, statusResult) = try await (days, statusMap)

        let total = daysResult.count
        guard total > 0 else { return (0, 0) }

        // Concluído = status true cujo id exista nos days (evita lixo)
        let dayIds = Set(daysResult.compactMap { $0.id })
        let completed = statusResult.filter { (key, value) in
            value == true && dayIds.contains(key)
        }.count

        return (completed, total)
    }

    /// ✅ Progresso geral do aluno (todas as semanas publicadas)
    /// Retorna: (completed, total, percent)
    func getStudentOverallProgress(studentId: String) async throws -> (completed: Int, total: Int, percent: Int) {

        let cleanStudentId = clean(studentId)
        guard !cleanStudentId.isEmpty else { throw RepositoryError.missingStudentId }

        // Considera apenas publicadas (pro aluno)
        let weeks = try await getWeeksForStudent(studentId: cleanStudentId, onlyPublished: true)
        let weekIds = weeks.compactMap { $0.id }.filter { !$0.isEmpty }

        guard !weekIds.isEmpty else { return (0, 0, 0) }

        var totalAll = 0
        var completedAll = 0

        // Paraleliza por weekId
        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            for wid in weekIds {
                group.addTask {
                    let p = try await self.getWeekProgress(weekId: wid)
                    return (p.completed, p.total)
                }
            }

            for try await (c, t) in group {
                completedAll += c
                totalAll += t
            }
        }

        let percent: Int
        if totalAll <= 0 {
            percent = 0
        } else {
            let v = (Double(completedAll) / Double(totalAll)) * 100.0
            percent = Int(v.rounded())
        }

        return (completedAll, totalAll, percent)
    }
}


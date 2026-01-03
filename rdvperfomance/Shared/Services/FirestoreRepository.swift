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
            "title": cleanTitle,
            "weekTitle": cleanTitle,
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
                    "title": titleTrim,
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

    // ============================================================
    // MARK: - ✅ PROGRESSO DO ALUNO (por semana)
    // ============================================================

    // Subcoleção: training_weeks/{weekId}/student_progress/{studentId}
    private let progressSubcollection = "student_progress"

    /// Retorna o mapa dayId -> Bool (concluído ou não) PARA UM ALUNO
    func getDayStatusMap(weekId: String, studentId: String) async throws -> [String: Bool] {
        let w = clean(weekId)
        let s = clean(studentId)
        guard !w.isEmpty else { throw RepositoryError.missingWeekId }
        guard !s.isEmpty else { throw RepositoryError.missingStudentId }

        let doc = try await db
            .collection(TrainingFS.weeksCollection)
            .document(w)
            .collection(progressSubcollection)
            .document(s)
            .getDocument()

        guard doc.exists else { return [:] }

        let data = doc.data() ?? [:]
        return data["completedMap"] as? [String: Bool] ?? [:]
    }

    /// Marca/desmarca um dia como concluído PARA UM ALUNO
    func setDayCompleted(weekId: String, studentId: String, dayId: String, completed: Bool) async throws {
        let w = clean(weekId)
        let s = clean(studentId)
        let d = clean(dayId)

        guard !w.isEmpty else { throw RepositoryError.missingWeekId }
        guard !s.isEmpty else { throw RepositoryError.missingStudentId }
        guard !d.isEmpty else { throw RepositoryError.invalidData }

        let ref = db
            .collection(TrainingFS.weeksCollection)
            .document(w)
            .collection(progressSubcollection)
            .document(s)

        // Usa "campo dinâmico" dentro de um map: completedMap.<dayId> = true/false
        try await ref.setData(
            [
                "studentId": s,
                "updatedAt": FieldValue.serverTimestamp(),
                "completedMap": [d: completed]
            ],
            merge: true
        )
    }

    /// Retorna (completed, total) PARA UM ALUNO naquela semana
    func getWeekProgress(weekId: String, studentId: String) async throws -> (completed: Int, total: Int) {
        let days = try await getDaysForWeek(weekId: weekId)
        let total = days.count

        guard total > 0 else { return (0, 0) }

        let map = try await getDayStatusMap(weekId: weekId, studentId: studentId)
        let completed = map.values.filter { $0 }.count

        return (completed, total)
    }

    // ============================================================
    // MARK: - ✅ PROGRESSO GERAL DO ALUNO (todas as semanas)
    // ============================================================

    /// Progresso geral em % considerando TODAS as semanas publicadas do aluno.
    /// Retorna Int percent (0..100). (Assinatura usada no seu TeacherStudentDetailView.)
    func getStudentOverallProgress(studentId: String) async throws -> (percent: Int, completed: Int, total: Int) {

        let s = clean(studentId)
        guard !s.isEmpty else { throw RepositoryError.missingStudentId }

        let weeks = try await getWeeksForStudent(studentId: s, onlyPublished: true)
        guard !weeks.isEmpty else { return (0, 0, 0) }

        var totalDays = 0
        var totalCompleted = 0

        // Carrega em paralelo por performance (MVP ok)
        try await withThrowingTaskGroup(of: (Int, Int).self) { group in
            for w in weeks {
                guard let weekId = w.id else { continue }
                group.addTask {
                    let p = try await self.getWeekProgress(weekId: weekId, studentId: s)
                    return (p.completed, p.total)
                }
            }

            for try await result in group {
                totalCompleted += result.0
                totalDays += result.1
            }
        }

        let percent: Int
        if totalDays > 0 {
            percent = Int(((Double(totalCompleted) / Double(totalDays)) * 100.0).rounded())
        } else {
            percent = 0
        }

        return (percent, totalCompleted, totalDays)
    }
}


import Foundation
import FirebaseFirestore

final class FirestoreRepository {

    static let shared = FirestoreRepository()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Errors
    enum RepositoryError: LocalizedError {
        case missingWeekId
        case missingUserId

        var errorDescription: String? {
            switch self {
            case .missingWeekId:
                return "Não foi possível carregar os dias: weekId está vazio ou nulo."
            case .missingUserId:
                return "Não foi possível identificar o usuário logado (uid vazio)."
            }
        }
    }

    // MARK: - users/{uid}
    func getUser(uid: String) async throws -> AppUser? {
        let clean = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { throw RepositoryError.missingUserId }

        let snap = try await db.collection("users").document(clean).getDocument()
        guard snap.exists else { return nil }

        return try snap.data(as: AppUser.self)
    }

    // MARK: - teacher_students (teacherId + categoria)
    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {

        let cleanTeacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTeacherId.isEmpty else { throw RepositoryError.missingUserId }

        let relSnap = try await db.collection("teacher_students")
            .whereField("teacherId", isEqualTo: cleanTeacherId)
            .whereField("categories", arrayContains: category)
            .getDocuments()

        let relations = try relSnap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }

        guard !relations.isEmpty else { return [] }

        // ✅ Busca alunos em paralelo
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

        // ordena por nome
        return students.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: - training_weeks por aluno
    func getWeeksForStudent(studentId: String) async throws -> [TrainingWeekFS] {

        let cleanStudentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanStudentId.isEmpty else { throw RepositoryError.missingUserId }

        let snap = try await db.collection("training_weeks")
            .whereField("studentId", isEqualTo: cleanStudentId)
            .getDocuments()

        let weeks = try snap.documents.compactMap { try $0.data(as: TrainingWeekFS.self) }

        // ✅ Ordena por weekTitle (campo que você já tem)
        return weeks.sorted { a, b in
            a.weekTitle.localizedCaseInsensitiveCompare(b.weekTitle) == .orderedAscending
        }
    }

    // MARK: - days subcollection
    func getDaysForWeek(weekId: String) async throws -> [TrainingDayFS] {

        let cleanWeekId = weekId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanWeekId.isEmpty else { throw RepositoryError.missingWeekId }

        let snap = try await db.collection("training_weeks")
            .document(cleanWeekId)
            .collection("days")
            .order(by: "order")
            .getDocuments()

        return try snap.documents.compactMap { try $0.data(as: TrainingDayFS.self) }
    }

    // MARK: - Helper seguro (resolve String? -> String)
    func getDays(for week: TrainingWeekFS) async throws -> [TrainingDayFS] {
        guard let weekId = week.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !weekId.isEmpty else {
            throw RepositoryError.missingWeekId
        }
        return try await getDaysForWeek(weekId: weekId)
    }
}


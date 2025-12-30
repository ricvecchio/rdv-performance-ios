import Foundation
import FirebaseFirestore

final class FirestoreRepository {

    private let db = Firestore.firestore()

    // MARK: - users/{uid}
    func getUser(uid: String) async throws -> AppUser? {
        let snap = try await db.collection("users").document(uid).getDocument()
        return try snap.data(as: AppUser.self)
    }

    // MARK: - teacher_students (filtra por teacherId e categoria)
    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {

        let relSnap = try await db.collection("teacher_students")
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("categories", arrayContains: category)
            .getDocuments()

        let relations = try relSnap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }

        // Busca cada aluno em users/{uid}
        var students: [AppUser] = []
        students.reserveCapacity(relations.count)

        for rel in relations {
            let studentSnap = try await db.collection("users").document(rel.studentId).getDocument()
            if let u = try? studentSnap.data(as: AppUser.self) {
                students.append(u)
            }
        }

        // ordena por nome
        return students.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // MARK: - training_weeks por aluno
    func getWeeksForStudent(studentId: String) async throws -> [TrainingWeekFS] {
        let snap = try await db.collection("training_weeks")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        let weeks = try snap.documents.compactMap { try $0.data(as: TrainingWeekFS.self) }
        return weeks.sorted { ($0.weekTitle) < ($1.weekTitle) }
    }

    // MARK: - days subcollection
    func getDaysForWeek(weekId: String) async throws -> [TrainingDayFS] {
        let snap = try await db.collection("training_weeks")
            .document(weekId)
            .collection("days")
            .order(by: "order")
            .getDocuments()

        return try snap.documents.compactMap { try $0.data(as: TrainingDayFS.self) }
    }
}


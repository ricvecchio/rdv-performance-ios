import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class UsersService {

    private let db = Firestore.firestore()

    // MARK: - Create / Upsert
    func upsertCurrentUserProfile(
        userType: UserTypeDTO,
        name: String,
        email: String,
        defaultCategory: String?,
        active: Bool?
    ) async throws {

        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "UsersService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado."]
            )
        }

        let docRef = db.collection(UserFS.collectionName).document(uid)

        let payload = UserFS(
            id: uid,
            name: name,
            email: email,
            userType: userType.rawValue, // ✅ userType
            defaultCategory: defaultCategory,
            teacherId: nil,
            active: active
        )

        try docRef.setData(from: payload, merge: true)
    }

    // MARK: - Queries (Professor)
    func fetchStudentsForTeacherFallbackAll() async throws -> [UserFS] {

        guard let teacherUid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "UsersService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado."]
            )
        }

        let base = db.collection(UserFS.collectionName)
            .whereField("userType", isEqualTo: UserTypeDTO.STUDENT.rawValue)

        // 1) tenta vinculados ao professor
        let linkedSnap = try await base
            .whereField("teacherId", isEqualTo: teacherUid)
            .getDocuments()

        let linked = linkedSnap.documents.compactMap {
            try? $0.data(as: UserFS.self)
        }
        if !linked.isEmpty { return linked }

        // 2) fallback educacional
        let allSnap = try await base.getDocuments()
        return allSnap.documents.compactMap {
            try? $0.data(as: UserFS.self)
        }
    }

    // MARK: - Vincular aluno ao professor
    func linkStudentToCurrentTeacher(studentId: String) async throws {

        guard let teacherUid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "UsersService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Usuário não autenticado."]
            )
        }

        let docRef = db.collection(UserFS.collectionName).document(studentId)
        try await docRef.setData(["teacherId": teacherUid], merge: true)
    }
}


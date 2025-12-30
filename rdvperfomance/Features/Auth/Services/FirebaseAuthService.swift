import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirebaseAuthServiceError: LocalizedError {
    case invalidState(String)

    var errorDescription: String? {
        switch self {
        case .invalidState(let msg): return msg
        }
    }
}

final class FirebaseAuthService {

    private let db = Firestore.firestore()

    // MARK: - Login
    func login(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    // MARK: - Register
    func register(_ form: RegisterFormDTO) async throws -> String {

        let result = try await Auth.auth().createUser(withEmail: form.email, password: form.password)
        let uid = result.user.uid

        // ✅ grava documento em users/{uid}
        var userDoc: [String: Any] = [
            "name": form.name,
            "email": form.email.lowercased(),
            "userType": form.userType.rawValue,
            "phone": form.phone ?? "",
            "focusArea": form.focusArea ?? "",
            "planType": form.planType,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if form.userType == .TRAINER {
            userDoc["cref"] = form.cref ?? ""
            userDoc["bio"] = form.bio ?? ""
            userDoc["gymName"] = form.gymName ?? ""
        } else {
            userDoc["defaultCategory"] = form.defaultCategory ?? "crossfit"
            userDoc["active"] = form.active ?? true
        }

        try await db.collection("users").document(uid).setData(userDoc, merge: true)
        return uid
    }

    // MARK: - Vincular aluno ao professor (teacher_students)
    func linkStudentToTeacher(teacherId: String, studentId: String, categories: [String]) async throws {

        // id simples para a relação (pode ser autoId)
        let relDoc: [String: Any] = [
            "teacherId": teacherId,
            "studentId": studentId,
            "categories": categories,
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("teacher_students").addDocument(data: relDoc)
    }
}


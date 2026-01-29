import Foundation
import FirebaseAuth
import FirebaseFirestore

// Erros customizados do serviço de autenticação
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

    // Realiza login com email e senha, retorna UID do usuário
    func login(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    // Cria usuário no Firebase Auth e salva perfil no Firestore
    func register(_ form: RegisterFormDTO) async throws -> String {

        let result = try await Auth.auth().createUser(withEmail: form.email, password: form.password)
        let uid = result.user.uid

        var userDoc: [String: Any] = [
            "name": form.name,
            "email": form.email.lowercased(),
            "userType": form.userType.rawValue,
            "phone": form.phone ?? "",
            "focusArea": form.focusArea ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if form.userType == .TRAINER {
            userDoc["cref"] = form.cref ?? ""
            userDoc["bio"] = form.bio ?? ""
            userDoc["gymName"] = form.gymName ?? ""
            userDoc["planType"] = "FREE"
            userDoc["trialStartedAt"] = FieldValue.serverTimestamp()
        } else {
            userDoc["defaultCategory"] = form.defaultCategory ?? "crossfit"
            userDoc["active"] = form.active ?? true
        }

        try await db.collection("users").document(uid).setData(userDoc, merge: true)
        return uid
    }

    // Cria vínculo entre professor e aluno na coleção teacher_students
    func linkStudentToTeacher(teacherId: String, studentId: String, categories: [String]) async throws {

        let relDoc: [String: Any] = [
            "teacherId": teacherId,
            "studentId": studentId,
            "categories": categories,
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("teacher_students").addDocument(data: relDoc)
    }
}


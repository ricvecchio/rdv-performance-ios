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
    // ✅ FIX: faz UPSERT (não duplica docs), normaliza categorias e atualiza updatedAt.
    func linkStudentToTeacher(teacherId: String, studentId: String, categories: [String]) async throws {

        let tid = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !tid.isEmpty else {
            throw FirebaseAuthServiceError.invalidState("teacherId inválido.")
        }
        guard !sid.isEmpty else {
            throw FirebaseAuthServiceError.invalidState("studentId inválido.")
        }

        let normalizedCategories = Array(
            Set(
                categories
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter { !$0.isEmpty }
            )
        ).sorted()

        guard !normalizedCategories.isEmpty else {
            throw FirebaseAuthServiceError.invalidState("Nenhuma categoria válida para vincular.")
        }

        // 1) Procura vínculo existente para (teacherId, studentId)
        let existing = try await db.collection("teacher_students")
            .whereField("teacherId", isEqualTo: tid)
            .whereField("studentId", isEqualTo: sid)
            .limit(to: 1)
            .getDocuments()

        if let doc = existing.documents.first {
            // 2) Atualiza categorias sem duplicar
            try await db.collection("teacher_students")
                .document(doc.documentID)
                .setData(
                    [
                        "categories": FieldValue.arrayUnion(normalizedCategories),
                        "updatedAt": FieldValue.serverTimestamp()
                    ],
                    merge: true
                )
        } else {
            // 3) Cria novo vínculo
            let relDoc: [String: Any] = [
                "teacherId": tid,
                "studentId": sid,
                "categories": normalizedCategories,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            try await db.collection("teacher_students").addDocument(data: relDoc)
        }
    }
}


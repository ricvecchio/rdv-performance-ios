import Foundation
import FirebaseAuth
import FirebaseFirestore

enum PersonalOrganizerError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        let locale = Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
        switch self {
        case .notSignedIn:
            return AppLocalization.string("account_security.errors.login_required", locale: locale)
        }
    }
}

/// Mantém os listeners do Firestore e os remove quando destruído.
final class PersonalOrganizerListenerBag {
    private var registrations: [ListenerRegistration] = []

    func add(_ registration: ListenerRegistration) {
        registrations.append(registration)
    }

    func removeAll() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }

    deinit { removeAll() }
}

/// Acesso ao Firestore para `users/{uid}/personal_notes|personal_reminders|personal_birthdays`.
/// Cada operação só é feita para o UID autenticado; não depende de professor vinculado.
final class PersonalOrganizerRepository {

    static let shared = PersonalOrganizerRepository()
    private let db = Firestore.firestore()
    private init() {}

    private func collection(uid: String, kind: PersonalOrganizerCollection) -> CollectionReference {
        db.collection("users").document(uid).collection(kind.rawValue)
    }

    private func requireAuthenticated(uid: String) throws {
        guard !uid.isEmpty, Auth.auth().currentUser?.uid == uid else {
            throw PersonalOrganizerError.notSignedIn
        }
    }

    func listen(
        uid: String,
        kind: PersonalOrganizerCollection,
        onChange: @escaping (QuerySnapshot?, Error?) -> Void
    ) -> ListenerRegistration {
        collection(uid: uid, kind: kind)
            .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                onChange(snapshot, error)
            }
    }

    func save(uid: String, kind: PersonalOrganizerCollection, id: String, data: [String: Any]) async throws {
        try requireAuthenticated(uid: uid)
        try await collection(uid: uid, kind: kind).document(id).setData(data)
    }

    func delete(uid: String, kind: PersonalOrganizerCollection, id: String) async throws {
        try requireAuthenticated(uid: uid)
        try await collection(uid: uid, kind: kind).document(id).delete()
    }

    /// Remove todos os registros pessoais do usuário (usado na exclusão de conta).
    func deleteAll(uid: String) async throws {
        try requireAuthenticated(uid: uid)
        for kind in PersonalOrganizerCollection.allCases {
            let snapshot = try await collection(uid: uid, kind: kind).getDocuments()
            guard !snapshot.documents.isEmpty else { continue }

            // Lotes de até 400 operações (limite do Firestore: 500)
            var index = 0
            let documents = snapshot.documents
            while index < documents.count {
                let batch = db.batch()
                for document in documents[index..<min(index + 400, documents.count)] {
                    batch.deleteDocument(document.reference)
                }
                try await batch.commit()
                index += 400
            }
        }
    }
}


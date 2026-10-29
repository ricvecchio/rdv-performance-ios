import Foundation
import FirebaseAuth
import FirebaseFirestore

enum PersonalOrganizerError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        PersonalOrganizerErrorKind(self).userMessage
    }
}

/// Causa de uma falha de leitura/gravação, para exibir mensagem localizada coerente
/// (nunca o texto técnico do Firebase).
enum PersonalOrganizerErrorKind: Equatable {
    case permission   // permissão negada ou sessão inválida
    case network      // sem conectividade
    case unexpected

    init(_ error: Error) {
        if error is PersonalOrganizerError {
            self = .permission
            return
        }
        let ns = error as NSError
        if ns.domain == FirestoreErrorDomain {
            switch FirestoreErrorCode.Code(rawValue: ns.code) {
            case .permissionDenied, .unauthenticated:
                self = .permission
            case .unavailable, .deadlineExceeded:
                self = .network
            default:
                self = .unexpected
            }
        } else if ns.domain == NSURLErrorDomain {
            self = .network
        } else {
            self = .unexpected
        }
    }

    private static var locale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    /// Mensagem para falhas de carregamento.
    var loadMessage: String {
        switch self {
        case .permission:
            return AppLocalization.string("personal.error.permission", locale: Self.locale)
        case .network:
            return AppLocalization.string("personal.error.network", locale: Self.locale)
        case .unexpected:
            return AppLocalization.string("personal.load_error", locale: Self.locale)
        }
    }

    /// Mensagem para falhas de gravação/exclusão.
    var userMessage: String {
        switch self {
        case .permission:
            return AppLocalization.string("personal.error.permission", locale: Self.locale)
        case .network:
            return AppLocalization.string("personal.error.network", locale: Self.locale)
        case .unexpected:
            return AppLocalization.string("personal.error.save", locale: Self.locale)
        }
    }

    static func message(for error: Error) -> String {
        PersonalOrganizerErrorKind(error).userMessage
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

/// Diagnóstico temporário (somente DEBUG). Não registra tokens nem conteúdo dos registros.
enum PersonalOrganizerDebug {
    static func log(
        _ operation: String,
        kind: PersonalOrganizerCollection,
        pathUid: String,
        error: Error? = nil
    ) {
        #if DEBUG
        let project = FirebaseApp.app()?.options.projectID ?? "nil"
        let authUid = Auth.auth().currentUser?.uid ?? "nil"
        var line = "[PersonalOrganizer] op=\(operation) path=users/\(pathUid)/\(kind.rawValue) "
            + "authUid=\(authUid) match=\(authUid == pathUid) project=\(project)"
        if let error {
            let ns = error as NSError
            line += " ERROR domain=\(ns.domain) code=\(ns.code) "
                + "(\(FirestoreErrorCode.Code(rawValue: ns.code).map { "\($0)" } ?? "?")) "
                + "desc=\(ns.localizedDescription)"
        } else {
            line += " OK"
        }
        print(line)
        #endif
    }
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
                PersonalOrganizerDebug.log("read", kind: kind, pathUid: uid, error: error)
                onChange(snapshot, error)
            }
    }

    func save(uid: String, kind: PersonalOrganizerCollection, id: String, data: [String: Any]) async throws {
        try requireAuthenticated(uid: uid)
        do {
            try await collection(uid: uid, kind: kind).document(id).setData(data)
            PersonalOrganizerDebug.log("write", kind: kind, pathUid: uid)
        } catch {
            PersonalOrganizerDebug.log("write", kind: kind, pathUid: uid, error: error)
            throw error
        }
    }

    func delete(uid: String, kind: PersonalOrganizerCollection, id: String) async throws {
        try requireAuthenticated(uid: uid)
        do {
            try await collection(uid: uid, kind: kind).document(id).delete()
            PersonalOrganizerDebug.log("delete", kind: kind, pathUid: uid)
        } catch {
            PersonalOrganizerDebug.log("delete", kind: kind, pathUid: uid, error: error)
            throw error
        }
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


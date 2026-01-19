import Foundation
import FirebaseFirestore

protocol FirestoreBaseRepository {
    var db: Firestore { get }
    func clean(_ value: String) -> String
}

extension FirestoreBaseRepository {
    func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

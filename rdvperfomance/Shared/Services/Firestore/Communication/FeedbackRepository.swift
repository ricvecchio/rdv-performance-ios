import Foundation
import FirebaseFirestore

final class FeedbackRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    private enum Collections {
        static let feedbacks = "student_feedbacks"
    }
    
    func createStudentFeedback(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        text: String
    ) async throws -> String {
        
        let t = clean(teacherId)
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let textTrim = clean(text)
        guard !textTrim.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let payload: [String: Any] = [
            "teacherId": t,
            "studentId": s,
            "categoryRaw": c,
            "text": textTrim,
            "authorType": "TRAINER",
            "authorId": t,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        let ref = db.collection(Collections.feedbacks).document()
        try await ref.setData(payload, merge: true)
        return ref.documentID
    }
    
    func getStudentFeedbacks(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [StudentFeedbackFS] {
        
        let t = clean(teacherId)
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        // ✅ SEM orderBy no Firestore
        let baseQuery: Query = db.collection(Collections.feedbacks)
            .whereField("teacherId", isEqualTo: t)
            .whereField("studentId", isEqualTo: s)
            .whereField("categoryRaw", isEqualTo: c)
            .limit(to: limit)
        
        let snap = try await baseQuery.getDocuments()
        let list = try snap.documents.compactMap { try $0.data(as: StudentFeedbackFS.self) }
        
        return list.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    func getFeedbacksForStudent(
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [StudentFeedbackFS] {
        
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let baseQuery: Query = db.collection(Collections.feedbacks)
            .whereField("studentId", isEqualTo: s)
            .whereField("categoryRaw", isEqualTo: c)
            .limit(to: limit)
        
        let snap = try await baseQuery.getDocuments()
        let list = try snap.documents.compactMap { try $0.data(as: StudentFeedbackFS.self) }
        
        return list.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
}

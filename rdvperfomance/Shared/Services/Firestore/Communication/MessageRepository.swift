import Foundation
import FirebaseFirestore

final class MessageRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    private enum Collections {
        static let messages = "teacher_messages"
    }
    
    func createTeacherMessage(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        subject: String?,
        body: String
    ) async throws -> String {
        
        let t = clean(teacherId)
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let subjectTrim = clean(subject ?? "")
        let bodyTrim = clean(body)
        guard !bodyTrim.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        var payload: [String: Any] = [
            "teacherId": t,
            "studentId": s,
            "categoryRaw": c,
            "body": bodyTrim,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if !subjectTrim.isEmpty {
            payload["subject"] = subjectTrim
        }
        
        let ref = db.collection(Collections.messages).document()
        try await ref.setData(payload, merge: true)
        return ref.documentID
    }
    
    func getTeacherMessages(
        teacherId: String,
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [TeacherMessageFS] {
        
        let t = clean(teacherId)
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        // ✅ SEM orderBy no Firestore (como no original)
        let baseQuery: Query = db.collection(Collections.messages)
            .whereField("teacherId", isEqualTo: t)
            .whereField("studentId", isEqualTo: s)
            .whereField("categoryRaw", isEqualTo: c)
            .limit(to: limit)
        
        let snap = try await baseQuery.getDocuments()
        let list = try snap.documents.compactMap { try $0.data(as: TeacherMessageFS.self) }
        
        // ✅ Ordena no app
        return list.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
    
    func getMessagesForStudent(
        studentId: String,
        categoryRaw: String,
        limit: Int = 50
    ) async throws -> [TeacherMessageFS] {
        
        let s = clean(studentId)
        let c = clean(categoryRaw)
        
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let baseQuery: Query = db.collection(Collections.messages)
            .whereField("studentId", isEqualTo: s)
            .whereField("categoryRaw", isEqualTo: c)
            .limit(to: limit)
        
        let snap = try await baseQuery.getDocuments()
        let list = try snap.documents.compactMap { try $0.data(as: TeacherMessageFS.self) }
        
        return list.sorted { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
    }
}

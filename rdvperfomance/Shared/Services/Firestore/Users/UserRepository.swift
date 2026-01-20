import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()
    
    private enum Collections {
        static let users = "users"
        static let teacherStudents = "teacher_students"
    }
    
    func getUser(uid: String) async throws -> AppUser? {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        
        let snap = try await db.collection(Collections.users).document(cleanUid).getDocument()
        guard snap.exists else { return nil }
        
        return try snap.data(as: AppUser.self)
    }
    
    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {
        let cleanTeacherId = clean(teacherId)
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        
        let relSnap = try await db.collection(Collections.teacherStudents)
            .whereField("teacherId", isEqualTo: cleanTeacherId)
            .whereField("categories", arrayContains: category)
            .getDocuments()
        
        let relations = try relSnap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }
        
        guard !relations.isEmpty else { return [] }
        
        let studentIds = relations.map { $0.studentId }
        
        let tasks: [Task<AppUser?, Never>] = studentIds.map { sid in
            Task {
                do {
                    let snap = try await self.db.collection(Collections.users).document(sid).getDocument()
                    guard snap.exists else { return nil }
                    return try snap.data(as: AppUser.self)
                } catch {
                    return nil
                }
            }
        }
        
        var students: [AppUser] = []
        students.reserveCapacity(tasks.count)
        
        for task in tasks {
            if let u = await task.value {
                students.append(u)
            }
        }
        
        return students.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func unlinkStudentFromTeacher(teacherId: String, studentId: String, category: String) async throws {
        let t = clean(teacherId)
        let s = clean(studentId)
        let c = clean(category)
        
        guard !t.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !s.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !c.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        let snap = try await db.collection(Collections.teacherStudents)
            .whereField("teacherId", isEqualTo: t)
            .whereField("studentId", isEqualTo: s)
            .getDocuments()
        
        guard !snap.documents.isEmpty else {
            throw FirestoreRepositoryError.notFound
        }
        
        let target = c.lowercased()
        
        for doc in snap.documents {
            let ref = doc.reference
            let data = doc.data()
            
            let categories = (data["categories"] as? [String]) ?? []
            
            let newCategories = categories.filter { clean($0).lowercased() != target }
            
            if newCategories.count == categories.count {
                continue
            }
            
            if newCategories.isEmpty {
                try await ref.delete()
            } else {
                try await ref.setData(
                    [
                        "categories": newCategories,
                        "updatedAt": FieldValue.serverTimestamp()
                    ],
                    merge: true
                )
            }
        }
    }
    
    func upsertUserProfile(uid: String, form: RegisterFormDTO) async throws {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        
        let payload: [String: Any] = [
            "name": form.name,
            "email": form.email,
            "userType": form.userType.rawValue,
            "phone": form.phone as Any,
            
            "focusArea": form.focusArea as Any,
            "planType": form.planType,
            
            "cref": form.cref as Any,
            "bio": form.bio as Any,
            "gymName": form.gymName as Any,
            
            "defaultCategory": form.defaultCategory as Any,
            "active": form.active as Any,
            
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection(Collections.users)
            .document(cleanUid)
            .setData(payload, merge: true)
    }
    
    // MARK: - Foto do Perfil
    func setUserPhotoBase64(uid: String, photoBase64: String) async throws {
        let u = clean(uid)
        let b64 = clean(photoBase64)
        guard !u.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        guard !b64.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        try await db.collection(Collections.users)
            .document(u)
            .setData(
                [
                    "photoBase64": b64,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    func clearUserPhotoBase64(uid: String) async throws {
        let u = clean(uid)
        guard !u.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        
        try await db.collection(Collections.users)
            .document(u)
            .setData(
                [
                    "photoBase64": FieldValue.delete(),
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    // MARK: - Unidade do Aluno
    func updateStudentUnitName(uid: String, unitName: String) async throws {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        
        let trimmed = unitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FirestoreRepositoryError.invalidData }
        
        try await db.collection(Collections.users)
            .document(cleanUid)
            .setData(
                [
                    "unitName": trimmed,
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }
    
    func setStudentUnitName(uid: String, unitName: String?) async throws {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        
        let trimmed = (unitName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        var payload: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if trimmed.isEmpty {
            payload["unitName"] = FieldValue.delete()
        } else {
            payload["unitName"] = trimmed
        }
        
        try await db.collection(Collections.users)
            .document(cleanUid)
            .setData(payload, merge: true)
    }
}

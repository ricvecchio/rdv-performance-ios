import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserRepository: FirestoreBaseRepository {
    let db = Firestore.firestore()

    private enum Collections {
        static let users = "users"
        static let teacherStudents = "teacher_students"
        static let relations = "teacher_student_relations"
        static let invites = "teacher_student_invites"
        static let requests = "teacher_student_link_requests"
    }

    // MARK: - Básico

    func getUser(uid: String) async throws -> AppUser? {
        let cleanUid = clean(uid)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        let snap = try await db.collection(Collections.users).document(cleanUid).getDocument()
        guard snap.exists else { return nil }
        return try snap.data(as: AppUser.self)
    }

    // MARK: - Professor por e-mail

    func getTeacherByEmail(email: String) async throws -> AppUser? {
        let e = clean(email).lowercased()
        guard !e.isEmpty else { return nil }

        // ✅ Não filtra por userType direto no Firestore (evita hardcode "TRAINER" e problemas com PROFESSOR/TEACHER)
        let snap = try await db.collection(Collections.users)
            .whereField("email", isEqualTo: e)
            .limit(to: 1)
            .getDocuments()

        guard let user = try snap.documents.first?.data(as: AppUser.self) else { return nil }

        // ✅ Aceita TRAINER / PROFESSOR / TEACHER (e variações comuns)
        let ut = user.userType.trimmingCharacters(in: .whitespacesAndNewlines)

        let allowed: Set<String> = [
            "TRAINER", "PROFESSOR", "TEACHER",
            "trainer", "professor", "teacher",
            "Trainer", "Professor", "Teacher"
        ]

        return allowed.contains(ut) ? user : nil
    }

    // MARK: - Relação ativa (status vinculado)

    func getActiveTeacherRelationForStudent(studentId: String) async throws -> TeacherStudentRelation? {
        let sid = clean(studentId)
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }

        let snap = try await db.collection(Collections.relations)
            .whereField("studentId", isEqualTo: sid)
            .limit(to: 1)
            .getDocuments()

        return try snap.documents.first?.data(as: TeacherStudentRelation.self)
    }

    func getTeacherLinksForStudent(studentId: String) async throws -> [TeacherStudentRelation] {
        let sid = clean(studentId)
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }

        let snap = try await db.collection(Collections.relations)
            .whereField("studentId", isEqualTo: sid)
            .getDocuments()

        return try snap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentRelation.self)
        }
    }

    private func ensureRelationDoc(teacherId: String, studentId: String) async throws -> DocumentReference {
        let existing = try await db.collection(Collections.relations)
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("studentId", isEqualTo: studentId)
            .limit(to: 1)
            .getDocuments()

        if let doc = existing.documents.first {
            return doc.reference
        }

        let relDoc = db.collection(Collections.relations).document()
        try await relDoc.setData([
            "teacherId": teacherId,
            "studentId": studentId,
            "categories": [],
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return relDoc
    }

    private func createPendingRequestIfNeeded(
        studentId: String,
        studentEmail: String,
        teacherId: String,
        teacherEmail: String
    ) async throws {
        let sid = clean(studentId)
        let sEmail = clean(studentEmail).lowercased()
        let tid = clean(teacherId)
        let tEmail = clean(teacherEmail).lowercased()

        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard sEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }
        guard tEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }

        let existing = try await db.collection(Collections.requests)
            .whereField("studentId", isEqualTo: sid)
            .whereField("teacherId", isEqualTo: tid)
            .whereField("status", isEqualTo: "pending")
            .limit(to: 1)
            .getDocuments()

        if existing.documents.first != nil {
            return
        }

        let docRef = db.collection(Collections.requests).document()
        try await docRef.setData([
            "studentId": sid,
            "studentEmail": sEmail,
            "teacherId": tid,
            "teacherEmail": tEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Convites (professor -> aluno)

    func getPendingInviteForStudentEmail(studentEmail: String) async throws -> TeacherStudentInviteFS? {
        let email = clean(studentEmail).lowercased()
        guard !email.isEmpty else { return nil }

        let snap = try await db.collection(Collections.invites)
            .whereField("studentEmail", isEqualTo: email)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        return try snap.documents.first?.data(as: TeacherStudentInviteFS.self)
    }

    func getInvitesForStudent(studentEmail: String) async throws -> [TeacherStudentInviteFS] {
        let email = clean(studentEmail).lowercased()
        guard !email.isEmpty else { return [] }

        let snap = try await db.collection(Collections.invites)
            .whereField("studentEmail", isEqualTo: email)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentInviteFS.self)
        }
    }

    func getInvitesSentByTeacher(
        teacherId: String,
        status: String?,
        limit: Int
    ) async throws -> [TeacherStudentInviteFS] {
        let tid = clean(teacherId)
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        var q: Query = db.collection(Collections.invites)
            .whereField("teacherId", isEqualTo: tid)

        let st = (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !st.isEmpty {
            q = q.whereField("status", isEqualTo: st)
        }

        q = q.order(by: "createdAt", descending: true)
            .limit(to: max(1, min(limit, 200)))

        let snap = try await q.getDocuments()
        return try snap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentInviteFS.self)
        }
    }

    func createTeacherInviteByEmail(
        teacherId: String,
        teacherEmail: String,
        studentEmail: String
    ) async throws -> String {
        let tid = clean(teacherId)
        let tEmail = clean(teacherEmail).lowercased()
        let sEmail = clean(studentEmail).lowercased()

        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard tEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }
        guard sEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }

        let existing = try await db.collection(Collections.invites)
            .whereField("teacherId", isEqualTo: tid)
            .whereField("studentEmail", isEqualTo: sEmail)
            .whereField("status", isEqualTo: "pending")
            .limit(to: 1)
            .getDocuments()

        if let doc = existing.documents.first {
            return doc.documentID
        }

        let docRef = db.collection(Collections.invites).document()
        try await docRef.setData([
            "teacherId": tid,
            "teacherEmail": tEmail,
            "studentEmail": sEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return docRef.documentID
    }

    func cancelTeacherInvite(inviteId: String) async throws {
        let id = clean(inviteId)
        guard !id.isEmpty else { throw FirestoreRepositoryError.invalidData }

        try await db.collection(Collections.invites)
            .document(id)
            .setData(
                [
                    "status": "cancelled",
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    func acceptInvite(invite: TeacherStudentInviteFS, studentId: String) async throws {
        let sid = clean(studentId)
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard let inviteId = invite.id else { throw FirestoreRepositoryError.invalidData }

        _ = try await ensureRelationDoc(teacherId: invite.teacherId, studentId: sid)

        try await db.collection(Collections.invites)
            .document(inviteId)
            .setData(
                [
                    "status": "accepted",
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )

        try await createPendingRequestIfNeeded(
            studentId: sid,
            studentEmail: invite.studentEmail,
            teacherId: invite.teacherId,
            teacherEmail: invite.teacherEmail
        )
    }

    func acceptStudentInvite(inviteId: String, studentId: String) async throws {
        let iid = clean(inviteId)
        let sid = clean(studentId)
        guard !iid.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }

        let snap = try await db.collection(Collections.invites).document(iid).getDocument()
        guard snap.exists else { throw FirestoreRepositoryError.notFound }

        let invite = try snap.data(as: TeacherStudentInviteFS.self)
        try await acceptInvite(invite: invite, studentId: sid)
    }

    func declineInvite(invite: TeacherStudentInviteFS) async throws {
        guard let inviteId = invite.id else { throw FirestoreRepositoryError.invalidData }

        try await db.collection(Collections.invites)
            .document(inviteId)
            .setData(
                [
                    "status": "declined",
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - Requests (aluno -> professor)

    func createLinkRequest(
        studentId: String,
        studentEmail: String,
        teacherId: String,
        teacherEmail: String
    ) async throws {
        let sid = clean(studentId)
        let sEmail = clean(studentEmail).lowercased()
        let tid = clean(teacherId)
        let tEmail = clean(teacherEmail).lowercased()

        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard sEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }
        guard tEmail.contains("@") else { throw FirestoreRepositoryError.invalidData }

        let existing = try await db.collection(Collections.requests)
            .whereField("studentId", isEqualTo: sid)
            .whereField("teacherId", isEqualTo: tid)
            .whereField("status", isEqualTo: "pending")
            .limit(to: 1)
            .getDocuments()

        if existing.documents.first != nil {
            return
        }

        let docRef = db.collection(Collections.requests).document()
        try await docRef.setData([
            "studentId": sid,
            "studentEmail": sEmail,
            "teacherId": tid,
            "teacherEmail": tEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    func getRequestsForStudent(studentId: String) async throws -> [TeacherStudentLinkRequestFS] {
        let sid = clean(studentId)
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }

        let snap = try await db.collection(Collections.requests)
            .whereField("studentId", isEqualTo: sid)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentLinkRequestFS.self)
        }
    }

    func getPendingLinkRequestsForTeacher(teacherId: String) async throws -> [TeacherStudentLinkRequestFS] {
        let tid = clean(teacherId)
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        let snap = try await db.collection(Collections.requests)
            .whereField("teacherId", isEqualTo: tid)
            .whereField("status", isEqualTo: "pending")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snap.documents.compactMap { doc in
            try doc.data(as: TeacherStudentLinkRequestFS.self)
        }
    }

    func approveLinkRequestAndLinkStudent(
        teacherId: String,
        requestId: String,
        studentId: String,
        category: String
    ) async throws {
        let tid = clean(teacherId)
        let rid = clean(requestId)
        let sid = clean(studentId)
        let cat = clean(category)

        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }
        guard !rid.isEmpty else { throw FirestoreRepositoryError.invalidData }
        guard !sid.isEmpty else { throw FirestoreRepositoryError.missingStudentId }
        guard !cat.isEmpty else { throw FirestoreRepositoryError.invalidData }

        let existing = try await db.collection(Collections.teacherStudents)
            .whereField("teacherId", isEqualTo: tid)
            .whereField("studentId", isEqualTo: sid)
            .limit(to: 1)
            .getDocuments()

        if let doc = existing.documents.first {
            try await db.collection(Collections.teacherStudents)
                .document(doc.documentID)
                .updateData([
                    "categories": FieldValue.arrayUnion([cat]),
                    "updatedAt": FieldValue.serverTimestamp()
                ])
        } else {
            try await db.collection(Collections.teacherStudents).addDocument(data: [
                "teacherId": tid,
                "studentId": sid,
                "categories": [cat],
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }

        let relRef = try await ensureRelationDoc(teacherId: tid, studentId: sid)
        try await relRef.setData(
            [
                "categories": FieldValue.arrayUnion([cat]),
                "updatedAt": FieldValue.serverTimestamp()
            ],
            merge: true
        )

        try await db.collection(Collections.requests)
            .document(rid)
            .setData(
                [
                    "status": "accepted",
                    "updatedAt": FieldValue.serverTimestamp()
                ],
                merge: true
            )
    }

    // MARK: - TeacherStudents (vínculo por categoria)

    private func categoryCandidates(from rawCategory: String) -> [String] {
        let base = clean(rawCategory)
        guard !base.isEmpty else { return [] }

        var set: [String] = []
        func add(_ v: String) {
            let c = clean(v)
            guard !c.isEmpty else { return }
            if set.contains(where: { $0 == c }) { return }
            set.append(c)
        }

        add(base)
        add(base.lowercased())
        add(base.uppercased())

        let lower = base.lowercased()
        if lower == "crossfit" || lower.contains("cross") {
            add("CROSSFIT")
            add("crossfit")
        } else if lower == "academia" || lower.contains("academ") || lower.contains("gym") {
            add("ACADEMIA")
            add("academia")
        } else if lower == "emcasa" || lower == "em_casa" || lower == "em casa" || lower == "emcasa " || lower.contains("casa") || lower.contains("home") || lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
            add("emCasa")
            add("emcasa")
            add("em_casa")
            add("em casa")
        } else if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" {
            add("EMCASA")
        } else if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" || lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        if lower == "emcasa" {
            add("EMCASA")
        }

        return set
    }

    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {
        let cleanTeacherId = clean(teacherId)
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        let candidates = categoryCandidates(from: category)
        if candidates.isEmpty { throw FirestoreRepositoryError.invalidData }

        var relSnap: QuerySnapshot? = nil

        for cat in candidates {
            let snap = try await db.collection(Collections.teacherStudents)
                .whereField("teacherId", isEqualTo: cleanTeacherId)
                .whereField("categories", arrayContains: cat)
                .getDocuments()

            if !snap.documents.isEmpty {
                relSnap = snap
                break
            }
        }

        guard let relSnap, !relSnap.documents.isEmpty else { return [] }

        let studentIds: [String] = relSnap.documents.compactMap { doc in
            let data = doc.data()
            let sid = (data["studentId"] as? String) ?? ""
            let cleaned = clean(sid)
            return cleaned.isEmpty ? nil : cleaned
        }

        if studentIds.isEmpty { return [] }

        var permissionDeniedCount: Int = 0
        var otherErrorsCount: Int = 0

        let tasks: [Task<AppUser?, Error>] = studentIds.map { sid in
            Task {
                do {
                    let snap = try await self.db.collection(Collections.users).document(sid).getDocument()
                    guard snap.exists else { return nil }
                    return try snap.data(as: AppUser.self)
                } catch {
                    throw error
                }
            }
        }

        var students: [AppUser] = []
        students.reserveCapacity(tasks.count)

        for task in tasks {
            do {
                if let u = try await task.value {
                    students.append(u)
                }
            } catch {
                let ns = error as NSError
                if ns.domain == FirestoreErrorDomain,
                   ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                    permissionDeniedCount += 1
                } else {
                    otherErrorsCount += 1
                }
            }
        }

        if students.isEmpty && permissionDeniedCount > 0 && otherErrorsCount == 0 {
            throw NSError(
                domain: FirestoreErrorDomain,
                code: FirestoreErrorCode.permissionDenied.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Sem permissão para ler /users/{studentId}. Ajuste as Firestore Rules para permitir que o professor leia o perfil do aluno vinculado."]
            )
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

        guard !snap.documents.isEmpty else { throw FirestoreRepositoryError.notFound }

        let targets = categoryCandidates(from: c).map { $0.lowercased() }
        if targets.isEmpty { throw FirestoreRepositoryError.invalidData }

        for doc in snap.documents {
            let ref = doc.reference
            let data = doc.data()
            let categories = (data["categories"] as? [String]) ?? []

            let newCategories = categories.filter { cat in
                let v = clean(cat).lowercased()
                return !targets.contains(v)
            }

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

    // MARK: - Perfil / Foto / Unidade

    func upsertUserProfile(uid: String, form: RegisterFormDTO) async throws {
        let cleanUid = uid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }

        let payload: [String: Any] = [
            "name": form.name,
            "email": form.email,
            "userType": form.userType.rawValue,
            "phone": form.phone as Any,
            "focusArea": form.focusArea as Any,
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


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

    func getUsers(byIds ids: [String]) async throws -> [String: AppUser] {
        let cleanIds = Array(Set(ids.map(clean).filter { !$0.isEmpty }))
        guard !cleanIds.isEmpty else { return [:] }
        return try await fetchUsers(byIds: cleanIds)
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
        studentEmail: String,
        categoryRaw: String? = nil
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

        var payload: [String: Any] = [
            "teacherId": tid,
            "teacherEmail": tEmail,
            "studentEmail": sEmail,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        // ✅ Categoria canônica (CROSSFIT | ACADEMIA | EMCASA) definida no momento do convite.
        // Isso permite que o aceite do aluno conclua o vínculo atomicamente, sem 2ª aprovação.
        if let raw = categoryRaw, let canonical = TreinoTipo.normalized(from: raw) {
            payload["category"] = canonical.firestoreKey
        }

        let docRef = db.collection(Collections.invites).document()
        try await docRef.setData(payload)

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

        let tid = clean(invite.teacherId)
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        // ✅ REGRA DE NEGÓCIO: se o professor já definiu a categoria ao enviar o convite,
        // o aceite do aluno é suficiente para concluir o vínculo — sem exigir uma 2ª
        // aprovação do professor. Tudo é gravado atomicamente em um único batch.
        if let rawCategory = invite.category, let canonical = TreinoTipo.normalized(from: rawCategory) {
            try await linkTeacherAndStudentAtomically(
                teacherId: tid,
                studentId: sid,
                category: canonical.firestoreKey,
                inviteId: inviteId
            )
            return
        }

        // ⚠️ Convite legado (sem categoria): mantém o fluxo em 2 etapas já existente —
        // o professor finaliza o vínculo escolhendo a categoria em "Vincular aluno".
        _ = try await ensureRelationDoc(teacherId: tid, studentId: sid)

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
            teacherId: tid,
            teacherEmail: invite.teacherEmail
        )
    }

    /// Localiza o documento existente de `teacherId`+`studentId` na coleção informada,
    /// ou reserva uma nova referência caso ainda não exista (Firestore não permite leitura
    /// dentro de um WriteBatch, por isso essa resolução acontece antes do commit).
    private func resolveOrCreateRef(
        in collection: String,
        teacherId: String,
        studentId: String
    ) async throws -> (ref: DocumentReference, isNew: Bool) {
        let existing = try await db.collection(collection)
            .whereField("teacherId", isEqualTo: teacherId)
            .whereField("studentId", isEqualTo: studentId)
            .limit(to: 1)
            .getDocuments()

        if let doc = existing.documents.first {
            return (doc.reference, false)
        }
        return (db.collection(collection).document(), true)
    }

    /// Conclui o vínculo professor/aluno de forma atômica: `teacher_student_relations`,
    /// `teacher_students` e o convite (`teacher_student_invites`) são gravados no mesmo
    /// WriteBatch, evitando estados intermediários inconsistentes (ex.: aluno "aceito"
    /// mas ainda não vinculado em `teacher_students`).
    private func linkTeacherAndStudentAtomically(
        teacherId: String,
        studentId: String,
        category: String,
        inviteId: String
    ) async throws {
        let (relationRef, relationIsNew) = try await resolveOrCreateRef(
            in: Collections.relations,
            teacherId: teacherId,
            studentId: studentId
        )

        let (teacherStudentRef, tsIsNew) = try await resolveOrCreateRef(
            in: Collections.teacherStudents,
            teacherId: teacherId,
            studentId: studentId
        )

        let batch = db.batch()

        var relationPayload: [String: Any] = [
            "teacherId": teacherId,
            "studentId": studentId,
            "categories": FieldValue.arrayUnion([category]),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if relationIsNew { relationPayload["createdAt"] = FieldValue.serverTimestamp() }
        batch.setData(relationPayload, forDocument: relationRef, merge: true)

        var teacherStudentPayload: [String: Any] = [
            "teacherId": teacherId,
            "studentId": studentId,
            "categories": FieldValue.arrayUnion([category]),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if tsIsNew { teacherStudentPayload["createdAt"] = FieldValue.serverTimestamp() }
        batch.setData(teacherStudentPayload, forDocument: teacherStudentRef, merge: true)

        batch.setData(
            [
                "status": "accepted",
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: db.collection(Collections.invites).document(inviteId),
            merge: true
        )

        try await batch.commit()
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

        let (teacherStudentRef, teacherStudentIsNew) = try await resolveOrCreateRef(
            in: Collections.teacherStudents,
            teacherId: tid,
            studentId: sid
        )
        let (relationRef, relationIsNew) = try await resolveOrCreateRef(
            in: Collections.relations,
            teacherId: tid,
            studentId: sid
        )

        let batch = db.batch()
        var teacherStudentPayload: [String: Any] = [
            "teacherId": tid,
            "studentId": sid,
            "categories": FieldValue.arrayUnion([cat]),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if teacherStudentIsNew { teacherStudentPayload["createdAt"] = FieldValue.serverTimestamp() }
        batch.setData(teacherStudentPayload, forDocument: teacherStudentRef, merge: true)

        var relationPayload: [String: Any] = [
            "teacherId": tid,
            "studentId": sid,
            "categories": FieldValue.arrayUnion([cat]),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if relationIsNew { relationPayload["createdAt"] = FieldValue.serverTimestamp() }
        batch.setData(relationPayload, forDocument: relationRef, merge: true)

        batch.setData(
            [
                "status": "accepted",
                "updatedAt": FieldValue.serverTimestamp()
            ],
            forDocument: db.collection(Collections.requests).document(rid),
            merge: true
        )

        try await batch.commit()
    }

    // MARK: - TeacherStudents (vínculo por categoria)

    /// Formato canônico das categorias daqui pra frente: `TreinoTipo.firestoreKey`
    /// ("CROSSFIT" | "ACADEMIA" | "EMCASA"). As variantes abaixo existem apenas para manter
    /// compatibilidade de LEITURA com registros antigos gravados em formatos diferentes
    /// (ex.: "crossfit", "emCasa", "em_casa"). Novos registros usam apenas `firestoreKey`.
    private func categoryCandidates(from rawCategory: String) -> [String] {
        let base = clean(rawCategory)
        guard !base.isEmpty else { return [] }

        var candidates: [String] = []
        func add(_ v: String) {
            let c = clean(v)
            guard !c.isEmpty, !candidates.contains(c) else { return }
            candidates.append(c)
        }

        add(base)
        add(base.lowercased())
        add(base.uppercased())

        if let canonical = TreinoTipo.normalized(from: base) {
            add(canonical.firestoreKey)
            add(canonical.firestoreKey.lowercased())
            add(canonical.rawValue)
        }

        return candidates
    }

    func getStudentsForTeacher(teacherId: String, category: String) async throws -> [AppUser] {
        let cleanTeacherId = clean(teacherId)
        guard !cleanTeacherId.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        guard let canonical = TreinoTipo.normalized(from: category) else {
            throw FirestoreRepositoryError.invalidData
        }

        // ✅ Reaproveita a busca agrupada (1 única query em teacher_students + leitura em
        // lote de /users) em vez de repetir consultas por variante de categoria.
        let grouped = try await getStudentsGroupedByTeacher(teacherId: cleanTeacherId)
        return grouped[canonical] ?? []
    }

    /// Retorna todos os alunos vinculados ao professor, já agrupados por categoria canônica,
    /// com o mínimo possível de leituras no Firestore:
    /// 1) uma única query em `teacher_students` (sem filtro de categoria);
    /// 2) leitura em lote de `/users/{id}` (chunks de até 30 ids via `FieldPath.documentID()`),
    ///    evitando o padrão N+1 de 1 getDocument() por aluno.
    func getStudentsGroupedByTeacher(teacherId: String) async throws -> [TreinoTipo: [AppUser]] {
        let tid = clean(teacherId)
        guard !tid.isEmpty else { throw FirestoreRepositoryError.missingTeacherId }

        let snap: QuerySnapshot
        do {
            snap = try await db.collection(Collections.teacherStudents)
                .whereField("teacherId", isEqualTo: tid)
                .getDocuments()
        } catch {
            throw error
        }

        // studentId -> categorias canônicas em que ele está vinculado
        var categoriesByStudent: [String: Set<TreinoTipo>] = [:]

        for doc in snap.documents {
            let data = doc.data()
            let sid = clean((data["studentId"] as? String) ?? "")
            guard !sid.isEmpty else { continue }

            let rawCategories = (data["categories"] as? [String]) ?? []
            var normalized: Set<TreinoTipo> = []
            for raw in rawCategories {
                if let cat = TreinoTipo.normalized(from: raw) {
                    normalized.insert(cat)
                }
            }
            guard !normalized.isEmpty else { continue }
            categoriesByStudent[sid, default: []].formUnion(normalized)
        }

        let studentIds = Array(categoriesByStudent.keys)
        guard !studentIds.isEmpty else { return [:] }

        let usersById = try await fetchUsers(byIds: studentIds)

        var result: [TreinoTipo: [AppUser]] = [:]
        for (sid, cats) in categoriesByStudent {
            guard let user = usersById[sid] else { continue }
            for cat in cats {
                result[cat, default: []].append(user)
            }
        }

        for key in result.keys {
            result[key]?.sort { $0.name.lowercased() < $1.name.lowercased() }
        }

        return result
    }

    /// Busca perfis de usuários em lote (`whereField(FieldPath.documentID(), in:)`), evitando
    /// 1 getDocument() por aluno. Distingue erro de permissão (Firestore Rules) de outros
    /// erros, para não mascarar `permissionDenied` como "lista vazia".
    private func fetchUsers(byIds ids: [String]) async throws -> [String: AppUser] {
        var result: [String: AppUser] = [:]
        var permissionDeniedCount = 0
        var otherErrorsCount = 0

        // Limite de 30 valores por cláusula "in" no Firestore.
        for chunk in ids.chunked(into: 30) {
            do {
                let snap = try await db.collection(Collections.users)
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                for doc in snap.documents {
                    if let user = try? doc.data(as: AppUser.self) {
                        result[doc.documentID] = user
                    }
                }
            } catch {
                let ns = error as NSError
                if ns.domain == FirestoreErrorDomain, ns.code == FirestoreErrorCode.permissionDenied.rawValue {
                    permissionDeniedCount += 1
                } else {
                    otherErrorsCount += 1
                }
            }
        }

        if result.isEmpty && permissionDeniedCount > 0 && otherErrorsCount == 0 {
            throw NSError(
                domain: FirestoreErrorDomain,
                code: FirestoreErrorCode.permissionDenied.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Sem permissão para ler /users/{studentId}. Ajuste as Firestore Rules para permitir que o professor leia o perfil dos alunos vinculados."]
            )
        }

        return result
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

    func updateUserProfile(
        uid: String,
        phone: String?,
        cref: String?,
        bio: String?,
        focusArea: String
    ) async throws {
        let cleanUid = clean(uid)
        let cleanPhone = clean(phone ?? "")
        let cleanFocusArea = clean(focusArea)

        guard !cleanUid.isEmpty else { throw FirestoreRepositoryError.missingUserId }
        guard !cleanFocusArea.isEmpty else { throw FirestoreRepositoryError.invalidData }

        var payload: [String: Any] = [
            "phone": cleanPhone.isEmpty ? FieldValue.delete() : cleanPhone,
            "focusArea": cleanFocusArea,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let cref {
            let cleanCref = clean(cref)
            payload["cref"] = cleanCref.isEmpty ? FieldValue.delete() : cleanCref
        }

        if let bio {
            let cleanBio = clean(bio)
            payload["bio"] = cleanBio.isEmpty ? FieldValue.delete() : cleanBio
        }

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

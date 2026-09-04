import Foundation
import Combine

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var hasLoadedStudents: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var isUnlinking: Bool = false

    @Published private(set) var invites: [TeacherStudentInviteFS] = []
    @Published private(set) var isInvitesLoading: Bool = false
    @Published private(set) var invitesErrorMessageInline: String? = nil

    @Published private(set) var pendingLinkRequests: [StudentLinkItem] = []
    @Published private(set) var isLinkRequestsLoading: Bool = false
    @Published var linkErrorMessage: String? = nil
    @Published var showLinkErrorAlert: Bool = false
    @Published var linkSuccessMessage: String? = nil
    @Published var showLinkSuccessAlert: Bool = false

    @Published var inviteErrorMessage: String? = nil
    @Published var showInviteErrorAlert: Bool = false

    @Published var inviteSuccessMessage: String? = nil
    @Published var showInviteSuccessAlert: Bool = false

    private let repository: FirestoreRepository

    private var studentsByCategory: [TreinoTipo: [AppUser]] = [:]
    private let supportedCategories: [TreinoTipo] = [.crossfit, .academia, .emCasa]
    private var activeTeacherId: String?
    private var teacherGeneration: Int = 0
    private var hasLoadedInvites: Bool = false
    private var hasLoadedLinkRequests: Bool = false
    private var studentsLoadTask: Task<Void, Never>?
    private var studentsLoadTeacherId: String?
    private var studentsRefreshRequested = false
    private var invitesLoadTask: Task<Void, Never>?
    private var invitesLoadTeacherId: String?
    private var invitesRefreshRequested = false
    private var linkRequestsLoadTask: Task<Void, Never>?
    private var linkRequestsLoadTeacherId: String?
    private var linkRequestsRefreshRequested = false

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    func clearActiveTeacherData() {
        guard activeTeacherId != nil else { return }
        activeTeacherId = nil
        invalidateTeacherData()
    }

    func loadStudents(teacherId: String, force: Bool = false) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return }
        activateTeacher(teacherId)

        if let task = studentsLoadTask, studentsLoadTeacherId == teacherId {
            if force {
                studentsRefreshRequested = true
            }
            await task.value
            return
        }

        guard force || !hasLoadedStudents else { return }

        let generation = teacherGeneration
        isLoading = true
        errorMessage = nil

        let task = Task { [weak self] in
            guard let self else { return }
            await self.performStudentsLoads(teacherId: teacherId, generation: generation)
        }
        studentsLoadTask = task
        studentsLoadTeacherId = teacherId
        await task.value
    }

    private func performStudentsLoads(teacherId: String, generation: Int) async {
        guard isActiveTeacher(teacherId, generation: generation) else { return }
        repeat {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            studentsRefreshRequested = false
            await performStudentsLoad(teacherId: teacherId, generation: generation)
        } while isActiveTeacher(teacherId, generation: generation) && studentsRefreshRequested

        guard isActiveTeacher(teacherId, generation: generation) else { return }
        studentsLoadTask = nil
        studentsLoadTeacherId = nil
        isLoading = false
    }

    private func performStudentsLoad(teacherId: String, generation: Int) async {
        do {
            // ✅ 1 única query em teacher_students (agrupada por categoria) em vez de
            // até 3 categorias x várias variantes de grafia = dezenas de queries.
            let grouped = try await repository.getStudentsGroupedByTeacher(teacherId: teacherId)
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            studentsByCategory = grouped
            students = mergeUniqueStudents(from: supportedCategories.compactMap { grouped[$0] })
            hasLoadedStudents = true
        } catch {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            if students.isEmpty {
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }

    func loadStudentsOnlyOneCategory(teacherId: String, category: TreinoTipo) async {
        _ = category
        await loadStudents(teacherId: teacherId)
    }

    func filteredStudents(filter: TreinoTipo?) -> [AppUser] {
        guard let filter else { return students }
        return studentsByCategory[filter] ?? []
    }

    func unlinkStudent(
        teacherId: String,
        studentId: String,
        categoryToRemove: TreinoTipo?
    ) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard activeTeacherId == teacherId else { return }
        let generation = teacherGeneration
        isUnlinking = true
        errorMessage = nil
        defer {
            if isActiveTeacher(teacherId, generation: generation) {
                isUnlinking = false
            }
        }
        var didUnlink = false

        if let cat = categoryToRemove {
            let variants = categoryVariants(cat)
            for v in variants {
                do {
                    try await repository.unlinkStudentFromTeacher(
                        teacherId: teacherId,
                        studentId: studentId,
                        category: v
                    )
                    didUnlink = true
                } catch {
                    continue
                }
            }
        } else {
            let catsToRemove = categoriesWhereStudentIsLinked(studentId: studentId)
            let effective = catsToRemove.isEmpty ? supportedCategories : catsToRemove

            for cat in effective {
                let variants = categoryVariants(cat)
                for v in variants {
                    do {
                        try await repository.unlinkStudentFromTeacher(
                            teacherId: teacherId,
                            studentId: studentId,
                            category: v
                        )
                        didUnlink = true
                    } catch {
                        continue
                    }
                }
            }
        }

        if didUnlink, isActiveTeacher(teacherId, generation: generation) {
            await loadStudents(teacherId: teacherId, force: true)
        }
    }


    func loadInvites(teacherId: String, force: Bool = false) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return }
        activateTeacher(teacherId)

        if let task = invitesLoadTask, invitesLoadTeacherId == teacherId {
            if force {
                invitesRefreshRequested = true
            }
            await task.value
            return
        }

        guard force || !hasLoadedInvites else { return }

        isInvitesLoading = true
        invitesErrorMessageInline = nil

        let generation = teacherGeneration
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performInvitesLoads(teacherId: teacherId, generation: generation)
        }
        invitesLoadTask = task
        invitesLoadTeacherId = teacherId
        await task.value
    }

    private func performInvitesLoads(teacherId: String, generation: Int) async {
        guard isActiveTeacher(teacherId, generation: generation) else { return }
        repeat {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            invitesRefreshRequested = false
            await performInvitesLoad(teacherId: teacherId, generation: generation)
        } while isActiveTeacher(teacherId, generation: generation) && invitesRefreshRequested

        guard isActiveTeacher(teacherId, generation: generation) else { return }
        invitesLoadTask = nil
        invitesLoadTeacherId = nil
        isInvitesLoading = false
    }

    private func performInvitesLoad(teacherId: String, generation: Int) async {
        do {
            let list = try await repository.getInvitesSentByTeacher(teacherId: teacherId, status: nil, limit: 50)
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            invites = list
            hasLoadedInvites = true
        } catch {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            if invites.isEmpty {
                invitesErrorMessageInline = (error as NSError).localizedDescription
            }
        }
    }

    func sendInviteByEmail(teacherId: String, studentEmail: String, category: TreinoTipo) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard activeTeacherId == teacherId else { return }
        let generation = teacherGeneration
        let email = studentEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            setInviteError("Informe o e-mail do aluno.")
            return
        }

        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer {
            if isActiveTeacher(teacherId, generation: generation) {
                isInvitesLoading = false
            }
        }

        do {
            let teacher = try await repository.getUser(uid: teacherId)
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            let teacherEmail = teacher?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if teacherEmail.isEmpty {
                setInviteError("Não foi possível identificar o e-mail do professor.")
                return
            }

            // ✅ A categoria já é conhecida no momento do convite (a tela está sempre
            // escopada a uma categoria). Isso permite que o aceite do aluno conclua o
            // vínculo atomicamente, sem exigir uma 2ª aprovação do professor.
            _ = try await repository.createTeacherInviteByEmail(
                teacherId: teacherId,
                teacherEmail: teacherEmail,
                studentEmail: email,
                categoryRaw: category.firestoreKey
            )

            guard isActiveTeacher(teacherId, generation: generation) else { return }
            inviteSuccessMessage = "Convite enviado para \(email)."
            showInviteSuccessAlert = true

            await loadInvites(teacherId: teacherId, force: true)

        } catch {
            if isActiveTeacher(teacherId, generation: generation) {
                setInviteError((error as NSError).localizedDescription)
            }
        }
    }

    /// Convites pendentes de alunos que ainda não possuem vínculo efetivo.
    var pendingInvites: [TeacherStudentInviteFS] {
        let linkedEmails = Set(
            students.map {
                $0.email
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
            }
            .filter { !$0.isEmpty }
        )

        return invites.filter {
            let isPending = $0.status
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == "pending"
            let inviteEmail = $0.studentEmail
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            return isPending && !linkedEmails.contains(inviteEmail)
        }
    }

    func cancelInvite(inviteId: String, teacherId: String) async {
        let id  = inviteId.trimmingCharacters(in: .whitespacesAndNewlines)
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, activeTeacherId == teacherId else { return }
        let generation = teacherGeneration

        // Remoção otimista: retira da lista imediatamente para resposta visual instantânea
        invites.removeAll { ($0.id ?? "") == id }

        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer {
            if isActiveTeacher(teacherId, generation: generation) {
                isInvitesLoading = false
            }
        }

        do {
            try await repository.cancelTeacherInvite(inviteId: id)
            guard isActiveTeacher(teacherId, generation: generation) else { return }

            // Resync com Firestore após cancelamento
            await loadInvites(teacherId: teacherId, force: true)
        } catch {
            if isActiveTeacher(teacherId, generation: generation) {
                setInviteError((error as NSError).localizedDescription)
            }
        }
    }

    func loadPendingLinkRequests(teacherId: String, force: Bool = false) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return }
        activateTeacher(teacherId)

        if let task = linkRequestsLoadTask, linkRequestsLoadTeacherId == teacherId {
            if force {
                linkRequestsRefreshRequested = true
            }
            await task.value
            return
        }

        guard force || !hasLoadedLinkRequests else { return }

        isLinkRequestsLoading = true

        let generation = teacherGeneration
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performLinkRequestsLoads(teacherId: teacherId, generation: generation)
        }
        linkRequestsLoadTask = task
        linkRequestsLoadTeacherId = teacherId
        await task.value
    }

    private func performLinkRequestsLoads(teacherId: String, generation: Int) async {
        guard isActiveTeacher(teacherId, generation: generation) else { return }
        repeat {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            linkRequestsRefreshRequested = false
            await performLinkRequestsLoad(teacherId: teacherId, generation: generation)
        } while isActiveTeacher(teacherId, generation: generation) && linkRequestsRefreshRequested

        guard isActiveTeacher(teacherId, generation: generation) else { return }
        linkRequestsLoadTask = nil
        linkRequestsLoadTeacherId = nil
        isLinkRequestsLoading = false
    }

    private func performLinkRequestsLoad(teacherId: String, generation: Int) async {
        do {
            let linkedStudentIds = Set(
                students.compactMap { student -> String? in
                    let id = student.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    return id.isEmpty ? nil : id
                }
            )
            let requests = try await repository.getPendingLinkRequestsForTeacher(teacherId: teacherId)
                .filter {
                    let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let studentId = $0.studentId.trimmingCharacters(in: .whitespacesAndNewlines)
                    return status == "pending" && !studentId.isEmpty && !linkedStudentIds.contains(studentId)
                }
            let usersById = try await repository.getUsers(byIds: requests.map(\.studentId))

            guard isActiveTeacher(teacherId, generation: generation) else { return }
            pendingLinkRequests = requests.compactMap { request in
                let requestId = request.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let studentId = request.studentId.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !requestId.isEmpty, !studentId.isEmpty else { return nil }

                let user = usersById[studentId]
                let email = (user?.email ?? request.studentEmail)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let name = user?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let displayName = name.isEmpty ? (email.isEmpty ? "Aluno" : email) : name

                return StudentLinkItem(
                    requestId: requestId,
                    studentId: studentId,
                    studentEmail: email,
                    name: displayName,
                    photoBase64: user?.photoBase64,
                    focusArea: user?.focusArea,
                    defaultCategory: user?.defaultCategory
                )
            }
            hasLoadedLinkRequests = true
        } catch {
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            if pendingLinkRequests.isEmpty {
                setLinkError((error as NSError).localizedDescription)
            }
        }
    }

    func removeLinkedStudentsFromPendingLinkRequests(teacherId: String) {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard activeTeacherId == teacherId else { return }
        let linkedStudentIds = Set(
            students.compactMap { student -> String? in
                let id = student.id?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return id.isEmpty ? nil : id
            }
        )
        pendingLinkRequests.removeAll { linkedStudentIds.contains($0.studentId) }
    }

    func approveRequestAndLinkStudent(
        teacherId: String,
        requestId: String,
        studentId: String,
        category: String
    ) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard activeTeacherId == teacherId else { return }
        let generation = teacherGeneration
        let id = requestId.trimmingCharacters(in: .whitespacesAndNewlines)
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !sid.isEmpty, !normalizedCategory.isEmpty else {
            setLinkError("Não foi possível identificar a solicitação de vínculo.")
            return
        }

        isLinkRequestsLoading = true
        defer {
            if isActiveTeacher(teacherId, generation: generation) {
                isLinkRequestsLoading = false
            }
        }

        do {
            try await repository.approveLinkRequestAndLinkStudent(
                teacherId: teacherId,
                requestId: id,
                studentId: sid,
                category: normalizedCategory
            )

            guard isActiveTeacher(teacherId, generation: generation) else { return }
            pendingLinkRequests.removeAll { $0.requestId == id }
            await loadStudents(teacherId: teacherId, force: true)
            await loadPendingLinkRequests(teacherId: teacherId, force: true)
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            linkSuccessMessage = "Aluno vinculado com sucesso."
            showLinkSuccessAlert = true
        } catch {
            if isActiveTeacher(teacherId, generation: generation) {
                setLinkError((error as NSError).localizedDescription)
            }
        }
    }

    func declineLinkRequest(teacherId: String, requestId: String) async {
        let teacherId = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard activeTeacherId == teacherId else { return }
        let generation = teacherGeneration
        let id = requestId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            setLinkError("Não foi possível identificar a solicitação de vínculo.")
            return
        }

        isLinkRequestsLoading = true

        do {
            try await repository.declineLinkRequest(requestId: id)
            guard isActiveTeacher(teacherId, generation: generation) else { return }
            pendingLinkRequests.removeAll { $0.requestId == id }
        } catch {
            if isActiveTeacher(teacherId, generation: generation) {
                isLinkRequestsLoading = false
                setLinkError((error as NSError).localizedDescription)
            }
            return
        }

        guard isActiveTeacher(teacherId, generation: generation) else { return }
        isLinkRequestsLoading = false
        await loadPendingLinkRequests(teacherId: teacherId, force: true)
    }

    func statusText(_ raw: String) -> String {
        let v = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if v == "pending" { return "Pendente" }
        if v == "accepted" { return "Aceito" }
        if v == "declined" { return "Recusado" }
        if v == "cancelled" { return "Cancelado" }
        return raw.isEmpty ? "—" : raw
    }

    func setInviteError(_ msg: String) {
        inviteErrorMessage = msg
        showInviteErrorAlert = true
    }

    func setLinkError(_ msg: String) {
        linkErrorMessage = msg
        showLinkErrorAlert = true
    }

    private func activateTeacher(_ teacherId: String) {
        guard activeTeacherId != teacherId else { return }
        activeTeacherId = teacherId
        invalidateTeacherData()
    }

    private func invalidateTeacherData() {
        teacherGeneration &+= 1

        studentsLoadTask?.cancel()
        invitesLoadTask?.cancel()
        linkRequestsLoadTask?.cancel()
        studentsLoadTask = nil
        invitesLoadTask = nil
        linkRequestsLoadTask = nil
        studentsLoadTeacherId = nil
        invitesLoadTeacherId = nil
        linkRequestsLoadTeacherId = nil
        studentsRefreshRequested = false
        invitesRefreshRequested = false
        linkRequestsRefreshRequested = false

        students = []
        studentsByCategory = [:]
        hasLoadedStudents = false
        invites = []
        hasLoadedInvites = false
        pendingLinkRequests = []
        hasLoadedLinkRequests = false

        isLoading = false
        isInvitesLoading = false
        isLinkRequestsLoading = false
        isUnlinking = false
        errorMessage = nil
        invitesErrorMessageInline = nil
        linkErrorMessage = nil
        showLinkErrorAlert = false
        linkSuccessMessage = nil
        showLinkSuccessAlert = false
        inviteErrorMessage = nil
        showInviteErrorAlert = false
        inviteSuccessMessage = nil
        showInviteSuccessAlert = false
    }

    private func isActiveTeacher(_ teacherId: String, generation: Int) -> Bool {
        activeTeacherId == teacherId && teacherGeneration == generation
    }

    private func categoryVariants(_ cat: TreinoTipo) -> [String] {
        // Mantido apenas para a rotina de desvínculo (unlinkStudentFromTeacher), que ainda
        // precisa remover categorias gravadas em formatos legados. Delegamos ao mesmo
        // normalizador canônico usado no repositório.
        [cat.firestoreKey, cat.rawValue]
    }

    private func categoriesWhereStudentIsLinked(studentId: String) -> [TreinoTipo] {
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sid.isEmpty else { return [] }

        return supportedCategories.filter { cat in
            let list = studentsByCategory[cat] ?? []
            return list.contains(where: { ($0.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == sid })
        }
    }

    private func mergeUniqueStudents(from lists: [[AppUser]]) -> [AppUser] {
        var seen: Set<String> = []
        var merged: [AppUser] = []

        for list in lists {
            for u in list {
                let key = uniqueKey(for: u)
                if seen.contains(key) { continue }
                seen.insert(key)
                merged.append(u)
            }
        }

        return merged.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    private func uniqueKey(for user: AppUser) -> String {
        if let id = user.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return id
        }
        let name = user.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let email = user.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(name)|\(email)"
    }
}

struct StudentLinkItem: Identifiable, Hashable {
    var id: String { requestId }

    let requestId: String
    let studentId: String
    let studentEmail: String
    let name: String
    let photoBase64: String?
    let focusArea: String?
    let defaultCategory: String?
}

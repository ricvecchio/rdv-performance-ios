import Foundation
import Combine

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var isUnlinking: Bool = false

    @Published private(set) var invites: [TeacherStudentInviteFS] = []
    @Published private(set) var isInvitesLoading: Bool = false
    @Published private(set) var invitesErrorMessageInline: String? = nil

    @Published var inviteErrorMessage: String? = nil
    @Published var showInviteErrorAlert: Bool = false

    @Published var inviteSuccessMessage: String? = nil
    @Published var showInviteSuccessAlert: Bool = false

    private let repository: FirestoreRepository

    private var studentsByCategory: [TreinoTipo: [AppUser]] = [:]
    private let supportedCategories: [TreinoTipo] = [.crossfit, .academia, .emCasa]

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    func loadStudents(teacherId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await withThrowingTaskGroup(of: (TreinoTipo, [AppUser]).self) { group in
                for cat in supportedCategories {
                    group.addTask {
                        let list = try await self.loadStudentsForCategoryWithFallback(
                            teacherId: teacherId,
                            category: cat
                        )
                        return (cat, list)
                    }
                }

                var collected: [(TreinoTipo, [AppUser])] = []
                for try await item in group { collected.append(item) }
                return collected
            }

            var map: [TreinoTipo: [AppUser]] = [:]
            for (cat, list) in results { map[cat] = list }
            self.studentsByCategory = map
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { map[$0] })

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
            self.studentsByCategory = [:]
            self.students = []
        }

        isLoading = false
    }

    func loadStudentsOnlyOneCategory(teacherId: String, category: TreinoTipo) async {
        isLoading = true
        errorMessage = nil

        do {
            let list = try await loadStudentsForCategoryWithFallback(
                teacherId: teacherId,
                category: category
            )

            studentsByCategory[category] = list
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { studentsByCategory[$0] })

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
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
        isUnlinking = true
        errorMessage = nil

        do {
            if let cat = categoryToRemove {
                let variants = categoryVariants(cat)
                for v in variants {
                    do {
                        try await repository.unlinkStudentFromTeacher(
                            teacherId: teacherId,
                            studentId: studentId,
                            category: v
                        )
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
                        } catch {
                            continue
                        }
                    }
                }
            }

            await loadStudents(teacherId: teacherId)

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isUnlinking = false
    }

    func loadInvites(teacherId: String) async {
        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer { isInvitesLoading = false }

        do {
            let list = try await repository.getInvitesSentByTeacher(teacherId: teacherId, status: nil, limit: 50)
            self.invites = list
        } catch {
            self.invites = []
            self.invitesErrorMessageInline = (error as NSError).localizedDescription
        }
    }

    func sendInviteByEmail(teacherId: String, studentEmail: String) async {
        let email = studentEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty else {
            setInviteError("Informe o e-mail do aluno.")
            return
        }

        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer { isInvitesLoading = false }

        do {
            let teacher = try await repository.getUser(uid: teacherId)
            let teacherEmail = teacher?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if teacherEmail.isEmpty {
                setInviteError("Não foi possível identificar o e-mail do professor.")
                return
            }

            _ = try await repository.createTeacherInviteByEmail(
                teacherId: teacherId,
                teacherEmail: teacherEmail,
                studentEmail: email
            )

            inviteSuccessMessage = "Convite enviado para \(email)."
            showInviteSuccessAlert = true

            let list = try await repository.getInvitesSentByTeacher(teacherId: teacherId, status: nil, limit: 50)
            self.invites = list

        } catch {
            setInviteError((error as NSError).localizedDescription)
        }
    }

    func cancelInvite(inviteId: String) async {
        let id = inviteId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }

        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer { isInvitesLoading = false }

        do {
            try await repository.cancelTeacherInvite(inviteId: id)
        } catch {
            setInviteError((error as NSError).localizedDescription)
        }
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

    private func loadStudentsForCategoryWithFallback(
        teacherId: String,
        category: TreinoTipo
    ) async throws -> [AppUser] {
        let variants = categoryVariants(category)
        var merged: [AppUser] = []

        for v in variants {
            let list = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: v
            )
            if !list.isEmpty {
                merged.append(contentsOf: list)
            }
        }

        return mergeUniqueStudents(from: [merged])
    }

    private func categoryVariants(_ cat: TreinoTipo) -> [String] {
        let raw = cat.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawLower = raw.lowercased()

        let key = cat.firestoreKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyLower = key.lowercased()

        var set: [String] = []
        func add(_ v: String) {
            let vv = v.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !vv.isEmpty else { return }
            if set.contains(vv) { return }
            set.append(vv)
        }

        add(key)
        add(keyLower)
        add(raw)
        add(rawLower)

        return set
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


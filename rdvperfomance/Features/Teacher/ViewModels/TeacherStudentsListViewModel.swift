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
        defer { isLoading = false }

        do {
            // ✅ 1 única query em teacher_students (agrupada por categoria) em vez de
            // até 3 categorias x várias variantes de grafia = dezenas de queries.
            let grouped = try await repository.getStudentsGroupedByTeacher(teacherId: teacherId)
            self.studentsByCategory = grouped
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { grouped[$0] })
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
            self.studentsByCategory = [:]
            self.students = []
        }
    }

    func loadStudentsOnlyOneCategory(teacherId: String, category: TreinoTipo) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let grouped = try await repository.getStudentsGroupedByTeacher(teacherId: teacherId)
            studentsByCategory[category] = grouped[category] ?? []
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { studentsByCategory[$0] })
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }
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

    func sendInviteByEmail(teacherId: String, studentEmail: String, category: TreinoTipo) async {
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

            // ✅ A categoria já é conhecida no momento do convite (a tela está sempre
            // escopada a uma categoria). Isso permite que o aceite do aluno conclua o
            // vínculo atomicamente, sem exigir uma 2ª aprovação do professor.
            _ = try await repository.createTeacherInviteByEmail(
                teacherId: teacherId,
                teacherEmail: teacherEmail,
                studentEmail: email,
                categoryRaw: category.firestoreKey
            )

            inviteSuccessMessage = "Convite enviado para \(email)."
            showInviteSuccessAlert = true

            let list = try await repository.getInvitesSentByTeacher(teacherId: teacherId, status: nil, limit: 50)
            self.invites = list

        } catch {
            setInviteError((error as NSError).localizedDescription)
        }
    }

    /// Convites com status `pending` que devem aparecer na tela principal.
    var pendingInvites: [TeacherStudentInviteFS] {
        invites.filter {
            $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pending"
        }
    }

    func cancelInvite(inviteId: String, teacherId: String) async {
        let id  = inviteId.trimmingCharacters(in: .whitespacesAndNewlines)
        let tid = teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }

        // Remoção otimista: retira da lista imediatamente para resposta visual instantânea
        invites.removeAll { ($0.id ?? "") == id }

        isInvitesLoading = true
        invitesErrorMessageInline = nil
        defer { isInvitesLoading = false }

        do {
            try await repository.cancelTeacherInvite(inviteId: id)

            // Resync com Firestore após cancelamento
            if !tid.isEmpty {
                let list = try await repository.getInvitesSentByTeacher(teacherId: tid, status: nil, limit: 50)
                self.invites = list
            }
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


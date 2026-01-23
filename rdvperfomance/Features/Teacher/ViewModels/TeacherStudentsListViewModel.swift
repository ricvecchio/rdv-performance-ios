// TeacherStudentsListViewModel.swift — ViewModel para gerenciar a lista de alunos do professor
import Foundation
import Combine

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    // Lista unificada de alunos e estados
    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var isUnlinking: Bool = false

    // ✅ NOVO: convites
    @Published private(set) var invites: [TeacherStudentInviteFS] = []
    @Published private(set) var isInvitesLoading: Bool = false
    @Published private(set) var invitesErrorMessageInline: String? = nil

    @Published var inviteErrorMessage: String? = nil
    @Published var showInviteErrorAlert: Bool = false

    @Published var inviteSuccessMessage: String? = nil
    @Published var showInviteSuccessAlert: Bool = false

    private let repository: FirestoreRepository

    // Cache por categoria e categorias suportadas
    private var studentsByCategory: [TreinoTipo: [AppUser]] = [:]
    private let supportedCategories: [TreinoTipo] = [.crossfit, .academia, .emCasa]

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    // Carrega alunos de todas as categorias em paralelo
    func loadStudents(teacherId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await withThrowingTaskGroup(of: (TreinoTipo, [AppUser]).self) { group in
                for cat in supportedCategories {
                    group.addTask {
                        let list = try await self.repository.getStudentsForTeacher(
                            teacherId: teacherId,
                            category: cat.rawValue
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
            let list = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: category.rawValue
            )

            studentsByCategory[category] = list
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { studentsByCategory[$0] })

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    // Retorna alunos filtrados por categoria
    func filteredStudents(filter: TreinoTipo?) -> [AppUser] {
        guard let filter else { return students }
        return studentsByCategory[filter] ?? []
    }

    // Desvincula um aluno (por categoria ou todas)
    func unlinkStudent(
        teacherId: String,
        studentId: String,
        categoryToRemove: TreinoTipo?
    ) async {
        isUnlinking = true
        errorMessage = nil

        do {
            if let cat = categoryToRemove {
                try await repository.unlinkStudentFromTeacher(
                    teacherId: teacherId,
                    studentId: studentId,
                    category: cat.rawValue
                )
            } else {
                let catsToRemove = categoriesWhereStudentIsLinked(studentId: studentId)
                let effective = catsToRemove.isEmpty ? supportedCategories : catsToRemove

                for cat in effective {
                    do {
                        try await repository.unlinkStudentFromTeacher(
                            teacherId: teacherId,
                            studentId: studentId,
                            category: cat.rawValue
                        )
                    } catch {
                        continue
                    }
                }
            }

            await loadStudents(teacherId: teacherId)

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isUnlinking = false
    }

    // MARK: - ✅ Convites (Professor -> Aluno)

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
            // Busca e-mail do professor pelo perfil (não depende do session ter email)
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

    // MARK: - Helpers existentes

    // Retorna categorias onde o aluno está vinculado
    private func categoriesWhereStudentIsLinked(studentId: String) -> [TreinoTipo] {
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sid.isEmpty else { return [] }

        return supportedCategories.filter { cat in
            let list = studentsByCategory[cat] ?? []
            return list.contains(where: { ($0.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == sid })
        }
    }

    // Une listas removendo duplicados
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

    // Gera chave única para identificar usuário
    private func uniqueKey(for user: AppUser) -> String {
        if let id = user.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return id
        }
        let name = user.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let email = user.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(name)|\(email)"
    }
}


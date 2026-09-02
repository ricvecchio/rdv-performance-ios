import Foundation
import Combine

@MainActor
final class StudentTeachersListViewModel: ObservableObject {

    @Published private(set) var linkedTeachers: [AppUser] = []
    @Published private(set) var sentRequests: [TeacherStudentLinkRequestFS] = []
    @Published private(set) var receivedInvites: [TeacherStudentInviteFS] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    func load(studentId: String, studentEmail: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let relations = repository.getTeacherLinksForStudent(studentId: studentId)
            async let requests = repository.getRequestsForStudent(studentId: studentId)
            async let invites = repository.getInvitesForStudent(studentEmail: studentEmail)
            let (links, allRequests, allInvites) = try await (relations, requests, invites)
            let linkedIds = Set(links.map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            let users = try await repository.getUsers(byIds: Array(linkedIds))

            linkedTeachers = linkedIds.compactMap { users[$0] }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sentRequests = allRequests.filter {
                $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pending"
                    && !linkedIds.contains($0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            receivedInvites = allInvites.filter {
                $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pending"
                    && !linkedIds.contains($0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        } catch {
            linkedTeachers = []
            sentRequests = []
            receivedInvites = []
            errorMessage = (error as NSError).localizedDescription
        }
    }

    func sendRequest(studentId: String, studentEmail: String, teacherEmail: String) async -> String? {
        let email = teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@"), email.contains(".") else { return "Informe um e-mail válido." }

        do {
            guard let teacher = try await repository.getTeacherByEmail(email: email),
                  let teacherId = teacher.id?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !teacherId.isEmpty else {
                return "Não encontrei um professor com esse e-mail."
            }
            if linkedTeachers.contains(where: { $0.id == teacherId }) {
                return "Esse professor já está vinculado."
            }
            if sentRequests.contains(where: { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) == teacherId }) {
                return "Já existe uma solicitação pendente para esse professor."
            }
            try await repository.createLinkRequest(
                studentId: studentId,
                studentEmail: studentEmail,
                teacherId: teacherId,
                teacherEmail: email
            )
            await load(studentId: studentId, studentEmail: studentEmail)
            return nil
        } catch {
            return (error as NSError).localizedDescription
        }
    }

    func accept(invite: TeacherStudentInviteFS, studentId: String, studentEmail: String) async {
        do {
            try await repository.acceptInvite(invite: invite, studentId: studentId)
            await load(studentId: studentId, studentEmail: studentEmail)
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    func decline(invite: TeacherStudentInviteFS, studentId: String, studentEmail: String) async {
        do {
            try await repository.declineInvite(invite: invite)
            await load(studentId: studentId, studentEmail: studentEmail)
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    func cancel(request: TeacherStudentLinkRequestFS, studentId: String, studentEmail: String) async {
        guard let requestId = request.id?.trimmingCharacters(in: .whitespacesAndNewlines),
              !requestId.isEmpty else {
            errorMessage = "Não foi possível identificar o convite."
            return
        }

        sentRequests.removeAll { $0.id == requestId }
        do {
            try await repository.cancelLinkRequest(requestId: requestId)
            await load(studentId: studentId, studentEmail: studentEmail)
        } catch {
            let message = (error as NSError).localizedDescription
            await load(studentId: studentId, studentEmail: studentEmail)
            errorMessage = message
        }
    }
}

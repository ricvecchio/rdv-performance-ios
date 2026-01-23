import Foundation
import Combine

@MainActor
final class StudentAgendaViewModel: ObservableObject {

    enum LinkBannerState: Equatable {
        case loading
        case notLinked
        case invitePending(teacherEmail: String)
        case linked
        case error(message: String)
    }

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var linkBannerState: LinkBannerState = .loading
    @Published private(set) var isProcessingLinkAction: Bool = false
    @Published var linkActionMessage: String? = nil
    @Published var linkActionMessageIsError: Bool = false

    private var hasLoadedLinkStatus: Bool = false

    private var weekRangeText: [String: String] = [:]
    private var weekProgressPercent: [String: Int] = [:]

    private let studentId: String
    private let repository: FirestoreRepository

    private var pendingInvite: TeacherStudentInviteFS? = nil
    private var currentStudentUser: AppUser? = nil

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    // MARK: - Link Status (Banner)

    func loadLinkStatusIfNeeded() async {
        guard !hasLoadedLinkStatus else { return }
        await loadLinkStatus(force: false)
    }

    func loadLinkStatus(force: Bool) async {
        if force { hasLoadedLinkStatus = false }

        linkBannerState = .loading
        linkActionMessage = nil
        linkActionMessageIsError = false

        do {
            // Carrega usuário do aluno (para obter email)
            currentStudentUser = try await repository.getUser(uid: studentId)

            // 1) Já existe vínculo?
            if let _ = try await repository.getActiveTeacherRelationForStudent(studentId: studentId) {
                linkBannerState = .linked
                hasLoadedLinkStatus = true
                return
            }

            // 2) Existe convite pendente?
            if let studentEmail = currentStudentUser?.email,
               !studentEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let invite = try await repository.getPendingInviteForStudentEmail(studentEmail: studentEmail) {
                    pendingInvite = invite
                    linkBannerState = .invitePending(teacherEmail: invite.teacherEmail)
                    hasLoadedLinkStatus = true
                    return
                }
            }

            // 3) Sem vínculo e sem convite
            linkBannerState = .notLinked
            hasLoadedLinkStatus = true

        } catch {
            linkBannerState = .error(message: (error as NSError).localizedDescription)
        }
    }

    func requestLinkByTeacherEmail(teacherEmail: String) async -> Bool {
        let email = teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard email.contains("@"), email.contains(".") else {
            linkActionMessage = "Informe um e-mail válido."
            linkActionMessageIsError = true
            return false
        }

        isProcessingLinkAction = true
        linkActionMessage = nil
        linkActionMessageIsError = false
        defer { isProcessingLinkAction = false }

        do {
            guard let teacher = try await repository.getTeacherByEmail(email: email),
                  let teacherId = teacher.id else {
                linkActionMessage = "Não encontrei um professor com esse e-mail."
                linkActionMessageIsError = true
                return false
            }

            if currentStudentUser == nil {
                currentStudentUser = try await repository.getUser(uid: studentId)
            }
            let studentEmail = (currentStudentUser?.email ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            try await repository.createLinkRequest(
                studentId: studentId,
                studentEmail: studentEmail,
                teacherId: teacherId,
                teacherEmail: email
            )

            linkActionMessage = "Solicitação enviada com sucesso."
            linkActionMessageIsError = false

            await loadLinkStatus(force: true)
            return true

        } catch {
            linkActionMessage = (error as NSError).localizedDescription
            linkActionMessageIsError = true
            return false
        }
    }

    func acceptPendingInvite() async {
        guard let invite = pendingInvite else { return }

        isProcessingLinkAction = true
        linkActionMessage = nil
        linkActionMessageIsError = false
        defer { isProcessingLinkAction = false }

        do {
            // passa o usuário do aluno (para decidir categoria inicial)
            if currentStudentUser == nil {
                currentStudentUser = try await repository.getUser(uid: studentId)
            }

            try await repository.acceptInvite(
                invite: invite,
                studentId: studentId,
                studentUser: currentStudentUser
            )

            pendingInvite = nil
            await loadLinkStatus(force: true)
        } catch {
            linkBannerState = .error(message: (error as NSError).localizedDescription)
        }
    }

    func declinePendingInvite() async {
        guard let invite = pendingInvite else { return }

        isProcessingLinkAction = true
        linkActionMessage = nil
        linkActionMessageIsError = false
        defer { isProcessingLinkAction = false }

        do {
            try await repository.declineInvite(invite: invite)
            pendingInvite = nil
            await loadLinkStatus(force: true)
        } catch {
            linkBannerState = .error(message: (error as NSError).localizedDescription)
        }
    }

    // MARK: - Semanas / Meta

    func loadWeeksAndMeta() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId)
            self.weeks = result
            await loadMetaForWeeks(result)
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }
    }

    private func loadMetaForWeeks(_ weeks: [TrainingWeekFS]) async {

        weekRangeText.removeAll()
        weekProgressPercent.removeAll()

        await withTaskGroup(of: Void.self) { group in
            for week in weeks {
                guard let weekId = week.id, !weekId.isEmpty else { continue }

                group.addTask { [studentId] in
                    do {
                        let days = try await self.repository.getDaysForWeek(weekId: weekId)
                        if let range = StudentAgendaViewModel.computeRangeTextStatic(days: days) {
                            await MainActor.run { self.weekRangeText[weekId] = range }
                        }

                        let p = try await self.repository.getWeekProgress(weekId: weekId, studentId: studentId)
                        let percent = StudentAgendaViewModel.computePercentStatic(completed: p.completed, total: p.total)
                        await MainActor.run { self.weekProgressPercent[weekId] = percent }
                    } catch {
                    }
                }
            }
        }

        objectWillChange.send()
    }

    func subtitleForWeek(_ week: TrainingWeekFS) -> String {
        guard let weekId = week.id else { return "Treinos da semana" }

        let range = weekRangeText[weekId] ?? "Treinos da semana"
        let percent = weekProgressPercent[weekId] ?? 0

        return "\(range) • \(percent)%"
    }

    nonisolated static func computePercentStatic(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let v = (Double(completed) / Double(total)) * 100.0
        return Int(v.rounded())
    }

    nonisolated static func computeRangeTextStatic(days: [TrainingDayFS]) -> String? {
        let dates = days.compactMap { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }

        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"

        return "\(f.string(from: minDate)) a \(f.string(from: maxDate))"
    }
}

import Foundation
import Combine

struct StudentDashboardDay: Identifiable {
    let weekId: String
    let weekTitle: String
    let day: TrainingDayFS
    let isCompleted: Bool

    var id: String { "\(weekId)-\(day.id ?? day.dayIndex.description)" }
}

struct StudentDashboardDaySummary: Identifiable {
    let date: Date
    let isCompleted: Bool

    var id: Date { date }
}

struct StudentDashboardNextFitModalityOption: Identifiable {
    let id: Int
    let title: String
}

enum StudentDashboardNextFitSelection: Hashable {
    case wod(Int)
    case agenda
}

enum StudentDashboardNextFitContentOption: Identifiable {
    case wod(id: Int, title: String)
    case agenda

    var id: StudentDashboardNextFitSelection { selection }

    var selection: StudentDashboardNextFitSelection {
        switch self {
        case .wod(let id, _):
            .wod(id)
        case .agenda:
            .agenda
        }
    }
}

struct StudentDashboardAgendaCancellationConfirmation: Equatable {
    let agendaId: Int
    let question: String
}

struct StudentDashboardDayGroup: Identifiable {
    let weekId: String
    let weekTitle: String
    let date: Date
    let workouts: [StudentDashboardDay]
    let completedCount: Int

    var id: String {
        "\(weekId)-\(Int(date.timeIntervalSinceReferenceDate))"
    }

    var totalCount: Int { workouts.count }
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var initialDayId: String? {
        workouts.compactMap { $0.day.id }.first
    }
}

enum StudentDashboardTeacherLinkState: Equatable {
    case loading
    case linked
    case unlinked
    case failed
}

@MainActor
final class StudentDashboardViewModel: ObservableObject {
    private static let primaryNextFitModalityCode = 262777
    @Published private(set) var currentWeekDaySummaries: [StudentDashboardDaySummary] = []
    @Published private(set) var upcomingDayGroups: [StudentDashboardDayGroup] = []
    @Published private(set) var isLoading = true
    @Published private(set) var teacherLinkState: StudentDashboardTeacherLinkState = .loading
    @Published private(set) var pendingTeacherInvites: [TeacherStudentInviteFS] = []
    @Published private(set) var isProcessingLinkAction = false
    @Published private(set) var isMuralhaStudent = false
    @Published private(set) var isLoadingNextFitWod = false
    @Published private(set) var nextFitWods: [NextFitWodDisplay] = []
    @Published private(set) var nextFitAgenda: [NextFitAgendaDisplay] = []
    @Published private(set) var selectedNextFitAgendaDate = Calendar.current.startOfDay(for: Date())
    @Published private(set) var nextFitAgendaWods: [NextFitWodDisplay] = []
    @Published private(set) var nextFitUpcomingWods: [NextFitUpcomingWodDisplay] = []
    @Published private(set) var isLoadingNextFitAgenda = false
    @Published private(set) var isLoadingNextFitAgendaWods = false
    @Published private(set) var nextFitAgendaWodError: String?
    @Published var selectedNextFitAgendaWodModalityId: Int?
    @Published private(set) var selectedNextFitAgendaId: Int?
    @Published private(set) var selectedNextFitAgendaDetail: NextFitAgendaDetailDisplay?
    @Published private(set) var isLoadingNextFitAgendaDetail = false
    @Published var selectedNextFitContent: StudentDashboardNextFitSelection?
    @Published private(set) var needsNextFitAuthentication = false
    @Published private(set) var hasNextFitSession = false
    @Published private(set) var nextFitError: String?
    @Published private(set) var nextFitAgendaError: String?
    @Published private(set) var nextFitAgendaDetailError: String?
    @Published private(set) var processingAgendaIds: Set<Int> = []
    @Published private(set) var agendaActionErrors: [Int: String] = [:]
    @Published private(set) var agendaCancellationConfirmation: StudentDashboardAgendaCancellationConfirmation?
    @Published private(set) var isAuthenticatingNextFit = false
    @Published var nextFitLoginError: String?
    @Published var linkActionMessage: String?
    @Published var linkActionMessageIsError = false

    private let studentId: String
    private let repository: FirestoreRepository
    private let nextFitService: NextFitService
    private var isLoadingData = false
    private var currentStudentUser: AppUser?
    private var nextFitContractClientIdsByModality: [Int: Int] = [:]

    var nextFitWod: NextFitWodDisplay? {
        guard case let .wod(modalityId)? = selectedNextFitContent else {
            return nil
        }
        return nextFitWods.first { $0.modalityId == modalityId }
    }

    var isNextFitAgendaSelected: Bool {
        selectedNextFitContent == .agenda
    }

    var isTomorrowAgendaSelected: Bool {
        Calendar.current.isDate(
            selectedNextFitAgendaDate,
            inSameDayAs: tomorrowAgendaDate
        )
    }

    var todayAgendaDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var tomorrowAgendaDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayAgendaDate) ?? todayAgendaDate
    }

    var nextFitAgendaDates: [Date] {
        let calendar = Calendar.current
        var dates = [todayAgendaDate]
        for wod in nextFitUpcomingWods {
            let date = calendar.startOfDay(for: wod.date)
            if !dates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                dates.append(date)
            }
        }
        return dates.sorted()
    }

    var nextFitAgendaWod: NextFitWodDisplay? {
        guard let modalityId = selectedNextFitAgendaWodModalityId else {
            return nil
        }
        return nextFitAgendaWods.first { $0.modalityId == modalityId }
    }

    func isProcessingAgenda(_ agendaId: Int) -> Bool {
        processingAgendaIds.contains(agendaId)
    }

    func isAgendaWithdrawal(_ agendaId: Int) -> Bool {
        if selectedNextFitAgendaDetail?.id == agendaId,
           let statusAgendaParticipante = selectedNextFitAgendaDetail?.statusAgendaParticipante {
            return statusAgendaParticipante == 8
        }
        return nextFitAgenda.first { $0.id == agendaId }?.statusAgendaParticipante == 8
    }

    func canCancelAgendaCheckIn(_ agendaId: Int) -> Bool {
        if selectedNextFitAgendaDetail?.id == agendaId,
           let hasCheckIn = selectedNextFitAgendaDetail?.hasCheckIn,
           let canCancelCheckIn = selectedNextFitAgendaDetail?.canCancelCheckIn {
            return hasCheckIn && canCancelCheckIn
        }
        return nextFitAgenda.first { $0.id == agendaId }?.canCancelCheckIn == true
    }

    func canScheduleAgendaCheckIn(_ agendaId: Int) -> Bool {
        if selectedNextFitAgendaDetail?.id == agendaId,
           let hasCheckIn = selectedNextFitAgendaDetail?.hasCheckIn,
           let canSchedule = selectedNextFitAgendaDetail?.canSchedule {
            return !hasCheckIn && canSchedule
        }
        return nextFitAgenda.first { $0.id == agendaId }?.canSchedule == true
    }

    func agendaActionError(for agendaId: Int) -> String? {
        agendaActionErrors[agendaId]
    }

    var nextFitModalityOptions: [StudentDashboardNextFitModalityOption] {
        nextFitWods.map {
            StudentDashboardNextFitModalityOption(
                id: $0.modalityId,
                title: $0.modalityName
            )
        }
    }

    var nextFitContentOptions: [StudentDashboardNextFitContentOption] {
        nextFitModalityOptions.map {
            .wod(id: $0.id, title: $0.title)
        } + [
            .agenda
        ]
    }

    var studentUnitName: String {
        (currentStudentUser?.unitName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(
        studentId: String,
        repository: FirestoreRepository,
        nextFitService: NextFitService = NextFitService()
    ) {
        self.studentId = studentId
        self.repository = repository
        self.nextFitService = nextFitService
    }

    func load(locale: Locale) async {
        hasNextFitSession = nextFitService.hasSession(sessionAccount: studentId)
        guard !isLoadingData else { return }
        isLoadingData = true
        isLoading = true
        teacherLinkState = .loading
        defer {
            isLoadingData = false
            isLoading = false
        }

        do {
            currentStudentUser = try await repository.getUser(uid: studentId)
            isMuralhaStudent = isMuralhaUnit(currentStudentUser?.unitName)
        } catch {
            currentStudentUser = nil
            isMuralhaStudent = false
        }

        let activeTeacherIds: Set<String>
        do {
            let teacherLinks = try await repository.getTeacherLinksForStudent(studentId: studentId)
            activeTeacherIds = Set(
                teacherLinks
                    .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
            teacherLinkState = activeTeacherIds.isEmpty ? .unlinked : .linked
        } catch {
            #if DEBUG
            print("[StudentDashboard] Não foi possível carregar os vínculos: \(error.localizedDescription)")
            #endif
            teacherLinkState = .failed
            activeTeacherIds = []
        }

        if teacherLinkState == .failed {
            pendingTeacherInvites = []
        } else {
            await loadPendingTeacherInvites(excludingTeacherIds: activeTeacherIds)
        }

        guard !activeTeacherIds.isEmpty else {
            currentWeekDaySummaries = []
            upcomingDayGroups = []
            return
        }


        do {
            let weeks = try await repository.getWeeksForStudent(studentId: studentId)
                .filter {
                    activeTeacherIds.contains(
                        $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let data = try await loadDays(for: weeks)
            currentWeekDaySummaries = makeCurrentWeekDaySummaries(
                from: data,
                today: today,
                calendar: calendar
            )
            upcomingDayGroups = makeUpcomingDayGroups(
                from: data,
                today: today,
                calendar: calendar
            )
        } catch {
            #if DEBUG
            print("[StudentDashboard] Não foi possível carregar a Home: \(error.localizedDescription)")
            #endif
            currentWeekDaySummaries = []
            upcomingDayGroups = []
        }

    }

    func loadNextFit(locale: Locale) async {
        do {
            currentStudentUser = try await repository.getUser(uid: studentId)
            isMuralhaStudent = isMuralhaUnit(currentStudentUser?.unitName)
        } catch {
            currentStudentUser = nil
            isMuralhaStudent = false
        }

        await loadNextFitWod(locale: locale)
    }

    func authenticateNextFit(email: String, password: String, locale: Locale) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            nextFitLoginError = AppLocalization.string("dashboard.nextfit.credentials_required",
                locale: locale
            )
            return false
        }

        isAuthenticatingNextFit = true
        nextFitLoginError = nil
        defer { isAuthenticatingNextFit = false }

        do {
            try await nextFitService.authenticate(
                email: trimmedEmail,
                password: password,
                sessionAccount: studentId
            )
            nextFitContractClientIdsByModality = [:]
            hasNextFitSession = true
            await loadNextFitWod(locale: locale)
            return true
        } catch let error as NextFitServiceError {
            nextFitLoginError = error.localizedDescription
            return false
        } catch {
            nextFitLoginError = AppLocalization.string("dashboard.nextfit.login_error",
                locale: locale
            )
            return false
        }
    }

    func retryNextFitWod(locale: Locale) async {
        await loadNextFitWod(locale: locale)
    }

    func selectNextFitAgendaDate(_ date: Date, locale: Locale) async {
        guard !isLoadingNextFitAgenda, !isLoadingNextFitAgendaWods else { return }

        let calendar = Calendar.current
        let selectedDate = calendar.startOfDay(for: date)
        guard nextFitAgendaDates.contains(where: {
            calendar.isDate($0, inSameDayAs: selectedDate)
        }) else {
            return
        }

        selectedNextFitAgendaDate = selectedDate
        agendaActionErrors = [:]
        clearNextFitAgendaDetail()
        nextFitAgendaError = nil
        nextFitAgendaWodError = nil
        nextFitAgendaWods = []
        selectedNextFitAgendaWodModalityId = nil
        isLoadingNextFitAgenda = true
        do {
            nextFitAgenda = try await nextFitService.loadAgenda(
                for: selectedDate,
                sessionAccount: studentId
            )
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitAgendaError = AppLocalization.string("dashboard.agenda.load_error", locale: locale)
            }
        } catch {
            nextFitAgendaError = AppLocalization.string("dashboard.agenda.load_error", locale: locale)
        }
        isLoadingNextFitAgenda = false

        await loadNextFitAgendaWods(for: selectedDate, locale: locale)
    }

    private func loadNextFitAgendaWods(for date: Date, locale: Locale) async {
        let calendar = Calendar.current
        var loadedModalityIds = Set<Int>()
        let dateWods = nextFitUpcomingWods.filter {
            calendar.isDate($0.date, inSameDayAs: date)
                && loadedModalityIds.insert($0.modalityId).inserted
        }
        guard !dateWods.isEmpty else { return }

        isLoadingNextFitAgendaWods = true
        defer { isLoadingNextFitAgendaWods = false }
        do {
            nextFitAgendaWods = try await nextFitService.loadWods(
                dateWods,
                sessionAccount: studentId
            )
            selectedNextFitAgendaWodModalityId = nextFitAgendaWods.first?.modalityId
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitAgendaWodError = AppLocalization.string("dashboard.agenda.wod_load_error", locale: locale)
            }
        } catch {
            nextFitAgendaWodError = AppLocalization.string("dashboard.agenda.wod_load_error", locale: locale)
        }
    }

    func selectNextFitAgenda(_ agendaId: Int, locale: Locale) async {
        guard !isLoadingNextFitAgendaDetail else { return }

        selectedNextFitAgendaId = agendaId
        selectedNextFitAgendaDetail = nil
        nextFitAgendaDetailError = nil
        isLoadingNextFitAgendaDetail = true
        defer { isLoadingNextFitAgendaDetail = false }

        do {
            selectedNextFitAgendaDetail = try await nextFitService.loadAgendaDetail(
                agendaId: agendaId,
                sessionAccount: studentId
            )
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitAgendaDetailError = AppLocalization.string("dashboard.agenda.detail_load_error", locale: locale)
            }
        } catch {
            nextFitAgendaDetailError = AppLocalization.string("dashboard.agenda.detail_load_error", locale: locale)
        }
    }

    func retryNextFitAgendaDetail(locale: Locale) async {
        guard let agendaId = selectedNextFitAgendaId else { return }
        await selectNextFitAgenda(agendaId, locale: locale)
    }

    func checkInAgenda(_ agendaId: Int, locale: Locale) async {
        guard let agenda = nextFitAgenda.first(where: { $0.id == agendaId }),
              !isAgendaWithdrawal(agendaId),
              agenda.endDate >= Date(),
              agenda.canSchedule else {
            return
        }
        guard processingAgendaIds.insert(agendaId).inserted else { return }
        agendaActionErrors[agendaId] = nil
        defer { processingAgendaIds.remove(agendaId) }

        do {
            #if DEBUG
            print("[NextFit Agenda] Iniciando agendamento. CodigoAgenda: \(agendaId)")
            #endif
            guard let contract = try await resolveNextFitAgendaContract(for: agendaId) else {
                agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.schedule_error", locale: locale)
                return
            }
            #if DEBUG
            print(
                "[NextFit Agenda] Check-in\n" +
                "CodigoAgenda: \(agendaId)\n" +
                "CodigoCliente: \(contract.clientId)\n" +
                "CodigoContratoCliente: \(contract.contractClientId)"
            )
            #endif
            try await nextFitService.checkInAgenda(
                agendaId: agendaId,
                contractClientId: contract.contractClientId,
                sessionAccount: studentId
            )
            await refreshNextFitAgenda(
                afterActionFor: agendaId,
                errorMessage: AppLocalization.string("dashboard.agenda.schedule_error", locale: locale),
                locale: locale
            )
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            case let .agendaCheckInBusinessFailure(_, message):
                agendaActionErrors[agendaId] = message
            default:
                agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.schedule_error", locale: locale)
            }
        } catch {
            agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.schedule_error", locale: locale)
        }
    }

    func cancelAgendaCheckIn(_ agendaId: Int, locale: Locale) async {
        guard let agenda = nextFitAgenda.first(where: { $0.id == agendaId }) else {
            return
        }

        let currentDate = Date()
        let canCancelCheckIn = canCancelAgendaCheckIn(agendaId)

        guard agenda.endDate >= currentDate else {
            return
        }
        guard canCancelCheckIn else {
            return
        }
        guard processingAgendaIds.insert(agendaId).inserted else {
            return
        }
        agendaActionErrors[agendaId] = nil
        defer { processingAgendaIds.remove(agendaId) }

        do {
            let response = try await nextFitService.cancelAgendaCheckIn(
                agendaId: agendaId,
                sessionAccount: studentId
            )
            await handleAgendaCancellationResponse(response, agendaId: agendaId, locale: locale)
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.cancel_error", locale: locale)
            }
        } catch {
            agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.cancel_error", locale: locale)
        }
    }

    func confirmAgendaCancellation(locale: Locale) async {
        guard let confirmation = agendaCancellationConfirmation else { return }
        let agendaId = confirmation.agendaId
        agendaCancellationConfirmation = nil
        guard processingAgendaIds.insert(agendaId).inserted else {
            return
        }
        agendaActionErrors[agendaId] = nil
        defer { processingAgendaIds.remove(agendaId) }
        do {
            let response = try await nextFitService.cancelAgendaCheckIn(
                agendaId: agendaId,
                confirmation: true,
                sessionAccount: studentId
            )
            await handleAgendaCancellationResponse(response, agendaId: agendaId, locale: locale)
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.cancel_error", locale: locale)
            }
        } catch {
            agendaActionErrors[agendaId] = AppLocalization.string("dashboard.agenda.cancel_error", locale: locale)
        }
    }

    func dismissAgendaCancellationConfirmation() {
        agendaCancellationConfirmation = nil
    }

    func clearNextFitAgendaDetail() {
        selectedNextFitAgendaId = nil
        selectedNextFitAgendaDetail = nil
        nextFitAgendaDetailError = nil
    }

    func logoutNextFit() throws {
        try nextFitService.logout(sessionAccount: studentId)
        nextFitContractClientIdsByModality = [:]
        nextFitWods = []
        nextFitAgenda = []
        nextFitAgendaWods = []
        nextFitUpcomingWods = []
        selectedNextFitAgendaWodModalityId = nil
        processingAgendaIds = []
        agendaActionErrors = [:]
        clearNextFitAgendaDetail()
        selectedNextFitContent = nil
        nextFitError = nil
        nextFitAgendaError = nil
        nextFitAgendaWodError = nil
        nextFitLoginError = nil
        hasNextFitSession = false
        needsNextFitAuthentication = true
    }

    func requestLinkByTeacherEmail(teacherEmail: String, locale: Locale) async -> Bool {
        let email = teacherEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard email.contains("@"), email.contains(".") else {
            linkActionMessage = AppLocalization.string(
                "student_teachers.link_request.invalid_email",
                locale: locale
            )
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
                linkActionMessage = AppLocalization.string(
                    "student_teachers.link_request.teacher_not_found",
                    locale: locale
                )
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

            linkActionMessage = AppLocalization.string(
                "student_teachers.link_request.success",
                locale: locale
            )
            linkActionMessageIsError = false
            await load(locale: locale)
            return true

        } catch {
            linkActionMessage = (error as NSError).localizedDescription
            linkActionMessageIsError = true
            return false
        }
    }

    private func loadPendingTeacherInvites(excludingTeacherIds linkedTeacherIds: Set<String>) async {
        do {
            guard let student = currentStudentUser else {
                pendingTeacherInvites = []
                return
            }

            let email = student.email
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !email.isEmpty else {
                pendingTeacherInvites = []
                return
            }

            pendingTeacherInvites = try await repository.getInvitesForStudent(studentEmail: email)
                .filter {
                    let status = $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let teacherId = $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                    return status == "pending"
                        && !teacherId.isEmpty
                        && !linkedTeacherIds.contains(teacherId)
                }
        } catch {
            pendingTeacherInvites = []
        }
    }

    private func loadNextFitWod(locale: Locale) async {
        guard !isLoadingNextFitWod else { return }

        isLoadingNextFitWod = true
        hasNextFitSession = nextFitService.hasSession(sessionAccount: studentId)
        nextFitError = nil
        nextFitAgendaError = nil
        nextFitAgendaWodError = nil
        nextFitWods = []
        nextFitAgenda = []
        nextFitAgendaWods = []
        selectedNextFitAgendaWodModalityId = nil
        selectedNextFitAgendaDate = todayAgendaDate
        processingAgendaIds = []
        agendaActionErrors = [:]
        clearNextFitAgendaDetail()
        selectedNextFitContent = nil
        needsNextFitAuthentication = false
        defer { isLoadingNextFitWod = false }

        do {
            nextFitWods = try await nextFitService.loadTodayWods(sessionAccount: studentId)
            let selectedModalityId = nextFitWods.first {
                $0.modalityId == Self.primaryNextFitModalityCode
            }?.modalityId ?? nextFitWods.first?.modalityId
            selectedNextFitContent = selectedModalityId.map(StudentDashboardNextFitSelection.wod) ?? .agenda
            #if DEBUG
            print("[NextFit Debug] ViewModel recebeu \(nextFitWods.count) modalidade(s).")
            #endif
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitError = error.localizedDescription
            }
        } catch {
            nextFitError = AppLocalization.string("dashboard.wod.load_error", locale: locale)
            return
        }

        do {
            nextFitAgenda = try await nextFitService.loadTodayAgenda(sessionAccount: studentId)
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitAgendaError = AppLocalization.string("dashboard.agenda.load_error", locale: locale)
            }
        } catch {
            nextFitAgendaError = AppLocalization.string("dashboard.agenda.load_error", locale: locale)
        }

        guard !needsNextFitAuthentication else { return }

        do {
            nextFitUpcomingWods = try await nextFitService.loadUpcomingWodDays(sessionAccount: studentId)
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                nextFitAgendaWodError = AppLocalization.string("dashboard.agenda.wod_load_error", locale: locale)
            }
            return
        } catch {
            nextFitAgendaWodError = AppLocalization.string("dashboard.agenda.wod_load_error", locale: locale)
            return
        }

        await loadNextFitAgendaWods(for: selectedNextFitAgendaDate, locale: locale)
    }

    private func resetNextFitWod() {
        isLoadingNextFitWod = false
        nextFitContractClientIdsByModality = [:]
        nextFitWods = []
        nextFitAgenda = []
        nextFitAgendaWods = []
        nextFitUpcomingWods = []
        selectedNextFitAgendaWodModalityId = nil
        selectedNextFitAgendaDate = todayAgendaDate
        processingAgendaIds = []
        agendaActionErrors = [:]
        clearNextFitAgendaDetail()
        selectedNextFitContent = nil
        hasNextFitSession = false
        needsNextFitAuthentication = false
        nextFitError = nil
        nextFitAgendaError = nil
        nextFitAgendaWodError = nil
        nextFitLoginError = nil
    }

    private func refreshNextFitAgenda(afterActionFor agendaId: Int, errorMessage: String, locale: Locale) async {
        do {
            nextFitAgenda = try await nextFitService.loadAgenda(
                for: selectedNextFitAgendaDate,
                sessionAccount: studentId
            )
            if selectedNextFitAgendaId == agendaId {
                await selectNextFitAgenda(agendaId, locale: locale)
            }
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                agendaActionErrors[agendaId] = errorMessage
            }
        } catch {
            agendaActionErrors[agendaId] = errorMessage
        }
    }

    private func handleAgendaCancellationResponse(
        _ response: NextFitAgendaCancelCheckInResponse,
        agendaId: Int,
        locale: Locale
    ) async {
        if let question = response.content?.question?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !question.isEmpty {
            agendaCancellationConfirmation = StudentDashboardAgendaCancellationConfirmation(
                agendaId: agendaId,
                question: question
            )
            return
        }

        agendaActionErrors[agendaId] = nil
        await refreshNextFitAgenda(
            afterActionFor: agendaId,
            errorMessage: AppLocalization.string("dashboard.agenda.cancel_error", locale: locale),
            locale: locale
        )
    }

    private func resolveNextFitAgendaContract(
        for agendaId: Int
    ) async throws -> (clientId: Int, contractClientId: Int)? {
        let clientId = try nextFitService.clientId(sessionAccount: studentId)
        let detail: NextFitAgendaDetailDisplay
        if let selectedNextFitAgendaDetail,
           selectedNextFitAgendaDetail.id == agendaId {
            detail = selectedNextFitAgendaDetail
        } else {
            detail = try await nextFitService.loadAgendaDetail(
                agendaId: agendaId,
                sessionAccount: studentId
            )
        }

        guard let modalityId = detail.modalityId else {
            return nil
        }

        if let contractClientId = nextFitContractClientIdsByModality[modalityId] {
            return (clientId, contractClientId)
        }

        let clientData = try await nextFitService.loadClientMainData(sessionAccount: studentId)
        guard clientData.clientId == clientId else {
            return nil
        }

        let activeContracts = clientData.contracts.filter { $0.status == 1 }

        guard let contract = activeContracts.first(
            where: { $0.modalities.contains(where: { $0.modalityId == modalityId }) }
        ) else {
            return nil
        }

        nextFitContractClientIdsByModality[modalityId] = contract.id
        return (clientId, contract.id)
    }

    private func isMuralhaUnit(_ unitName: String?) -> Bool {
        let normalized = (unitName ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return normalized == "muralha" || normalized == "crossfit muralha"
    }

    private func loadDays(for weeks: [TrainingWeekFS]) async throws -> [StudentDashboardDay] {
        try await withThrowingTaskGroup(of: [StudentDashboardDay].self) { group in
            for week in weeks {
                guard let weekId = week.id, !weekId.isEmpty else { continue }
                group.addTask {
                    async let days = self.repository.getDaysForWeek(weekId: weekId)
                    async let completionMap = self.repository.getDayStatusMap(
                        weekId: weekId,
                        studentId: self.studentId
                    )
                    let (loadedDays, loadedCompletionMap) = try await (days, completionMap)
                    return loadedDays.map {
                        StudentDashboardDay(
                            weekId: weekId,
                            weekTitle: week.weekTitle,
                            day: $0,
                            isCompleted: $0.id.flatMap { loadedCompletionMap[$0] } == true
                        )
                    }
                }
            }

            var result: [StudentDashboardDay] = []
            for try await days in group {
                result.append(contentsOf: days)
            }
            return result
        }
    }

    private func makeCurrentWeekDaySummaries(
        from days: [StudentDashboardDay],
        today: Date,
        calendar: Calendar
    ) -> [StudentDashboardDaySummary] {
        guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }

        let daysByDate = Dictionary(grouping: days) { item in
            calendar.startOfDay(for: item.day.date ?? .distantPast)
        }

        return daysByDate
            .filter { date, _ in currentWeek.contains(date) }
            .map { date, days in
                StudentDashboardDaySummary(
                    date: date,
                    isCompleted: days.allSatisfy(\.isCompleted)
                )
            }
            .sorted { $0.date < $1.date }
    }

    private func makeUpcomingDayGroups(
        from days: [StudentDashboardDay],
        today: Date,
        calendar: Calendar
    ) -> [StudentDashboardDayGroup] {
        let grouped = Dictionary(grouping: days.compactMap { item -> (String, Date, StudentDashboardDay)? in
            guard let date = item.day.date else { return nil }
            let normalizedDate = calendar.startOfDay(for: date)
            return ("\(item.weekId)-\(Int(normalizedDate.timeIntervalSinceReferenceDate))", normalizedDate, item)
        }, by: \.0)

        return grouped.compactMap { _, entries in
            guard let first = entries.first else { return nil }
            let workouts = entries.map(\.2)
            return StudentDashboardDayGroup(
                weekId: first.2.weekId,
                weekTitle: first.2.weekTitle,
                date: first.1,
                workouts: workouts,
                completedCount: workouts.filter(\.isCompleted).count
            )
        }
        .filter { $0.date >= today && $0.completedCount < $0.totalCount }
        .sorted { $0.date < $1.date }
        .prefix(3)
        .map { $0 }
    }
}

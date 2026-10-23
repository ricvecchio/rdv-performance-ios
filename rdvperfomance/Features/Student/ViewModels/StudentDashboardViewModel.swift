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
    @Published private(set) var currentWeekCheckInSummaries: [StudentDashboardDaySummary] =
        StudentDashboardViewModel.makeCurrentWeekCheckInSummaries(checkedInDays: [])
    @Published private(set) var isLoadingCurrentWeekCheckIns = false
    /// Aulas de hoje com participação confirmada do aluno autenticado (lembrete "Seu check-in de hoje" da Home)
    @Published private(set) var todayConfirmedCheckIns: [NextFitAgendaDisplay] = []

    private let studentId: String
    // Identifica a consulta mais recente do lembrete de check-in (descarta resultados antigos)
    private var todayConfirmedCheckInsGeneration = 0
    private let repository: FirestoreRepository
    private let nextFitService: NextFitService
    private var isLoadingData = false
    private var currentStudentUser: AppUser?
    private var nextFitContractClientIdsByModality: [Int: Int] = [:]
    // Contratos do próprio aluno autenticado (mesmo CodigoCliente da sessão), em memória e carregados
    // no máximo uma vez por sessão; nunca atribuídos a outros participantes.
    @Published private var nextFitOwnContracts: (clientId: Int, contracts: [NextFitClientMainDataResponse.Content.Contract])?
    private var isLoadingOwnNextFitContracts = false

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

    func loadCurrentWeekCheckIns() async {
        let calendar = Self.checkInWeekCalendar
        let today = calendar.startOfDay(for: Date())
        let weekDates = Self.currentCheckInWeekDates(calendar: calendar)

        guard nextFitService.hasSession(sessionAccount: studentId) else {
            currentWeekCheckInSummaries = Self.makeCurrentWeekCheckInSummaries(checkedInDays: [])
            isLoadingCurrentWeekCheckIns = false
            return
        }

        isLoadingCurrentWeekCheckIns = true
        var checkedInDays = Set<Date>()
        var failedDays = Set<Date>()
        // Identidade NextFit do aluno autenticado (CodigoCliente do token da sessão) usada
        // para localizar o aluno na lista de participantes das aulas.
        var participantIdentity = WeeklyCheckInParticipantIdentity(
            clientId: try? nextFitService.clientId(sessionAccount: studentId)
        )

        for date in weekDates where date <= today {
            if Task.isCancelled { return }
            do {
                let agenda = try await nextFitService.loadAgenda(for: date, sessionAccount: studentId)
                #if DEBUG
                print("[StudentDashboard] Check-ins: \(agenda.count) aula(s) retornada(s) para \(date).")
                #endif
                // Aulas cuja lista de participantes já foi verificada nesta data (evita chamadas repetidas)
                var verifiedAgendaIds = Set<Int>()
                var participation = try await weeklyCheckInParticipation(
                    in: agenda,
                    on: date,
                    calendar: calendar,
                    identity: &participantIdentity,
                    verifiedAgendaIds: &verifiedAgendaIds
                )
                if Task.isCancelled { return }
                // Dias anteriores: a consulta padrão da Agenda (FiltrarHistorico=false) pode não
                // retornar as aulas já encerradas. Somente para este resumo, e apenas quando a
                // participação ainda não foi confirmada, consulta também o histórico da data.
                // A conclusão continua exigindo FezCheckin ou o aluno na lista de participantes.
                if participation != .confirmed, date < today {
                    let historyParticipation: WeeklyCheckInDayParticipation
                    do {
                        let history = try await nextFitService.loadAgenda(
                            for: date,
                            sessionAccount: studentId,
                            includeHistory: true
                        )
                        #if DEBUG
                        print("[StudentDashboard] Check-ins (histórico): \(history.count) aula(s) retornada(s) para \(date).")
                        #endif
                        historyParticipation = try await weeklyCheckInParticipation(
                            in: history,
                            on: date,
                            calendar: calendar,
                            identity: &participantIdentity,
                            verifiedAgendaIds: &verifiedAgendaIds
                        )
                    } catch NextFitServiceError.missingSession {
                        throw NextFitServiceError.missingSession
                    } catch NextFitServiceError.invalidSession {
                        throw NextFitServiceError.invalidSession
                    } catch {
                        // Falha temporária no histórico não confirma ausência
                        historyParticipation = .indeterminate
                    }
                    if Task.isCancelled { return }
                    if historyParticipation == .confirmed {
                        participation = .confirmed
                    } else if historyParticipation == .indeterminate {
                        participation = .indeterminate
                    }
                }
                switch participation {
                case .confirmed:
                    checkedInDays.insert(date)
                case .notConfirmed:
                    break
                case .indeterminate:
                    // Falha ao consultar a lista de participantes não confirma ausência
                    failedDays.insert(date)
                }
            } catch NextFitServiceError.missingSession, NextFitServiceError.invalidSession {
                if Task.isCancelled { return }
                // Sessão NextFit ausente ou expirada: solicita nova autenticação (mesmo tratamento dos demais fluxos)
                currentWeekCheckInSummaries = Self.makeCurrentWeekCheckInSummaries(checkedInDays: [])
                isLoadingCurrentWeekCheckIns = false
                needsNextFitAuthentication = true
                hasNextFitSession = false
                return
            } catch {
                if Task.isCancelled { return }
                // Falha temporária não confirma ausência de check-in
                failedDays.insert(date)
                #if DEBUG
                print("[StudentDashboard] Não foi possível carregar os check-ins do dia: \(error.localizedDescription)")
                #endif
            }
        }

        guard !Task.isCancelled else { return }

        // Preserva o último resultado válido dos dias cuja consulta falhou
        for date in failedDays where currentWeekCheckInSummaries.contains(where: {
            $0.isCompleted && calendar.isDate($0.date, inSameDayAs: date)
        }) {
            checkedInDays.insert(date)
        }

        currentWeekCheckInSummaries = Self.makeCurrentWeekCheckInSummaries(checkedInDays: checkedInDays)
        isLoadingCurrentWeekCheckIns = false
    }

    // MARK: - Participação confirmada (exclusivo do resumo semanal de Check-in)

    private enum WeeklyCheckInDayParticipation {
        case confirmed
        case notConfirmed
        case indeterminate
    }

    private struct WeeklyCheckInParticipantIdentity {
        let clientId: Int?
        // Contratos (CodigoContratoCliente) do aluno, carregados somente se necessário
        var contractClientIds: Set<Int>?
    }

    /// StatusAgendaParticipante já tratado no app como "Desistente" (ver `isAgendaWithdrawal`).
    private static let weeklyCheckInWithdrawnStatus = 8

    /// Determina se o aluno autenticado consta como participante confirmado em ao menos
    /// uma aula do dia. Não altera a Agenda exibida nem a semântica de `hasCheckIn`.
    private func weeklyCheckInParticipation(
        in agenda: [NextFitAgendaDisplay],
        on date: Date,
        calendar: Calendar,
        identity: inout WeeklyCheckInParticipantIdentity,
        verifiedAgendaIds: inout Set<Int>
    ) async throws -> WeeklyCheckInDayParticipation {
        let dayEntries = agenda.filter {
            calendar.isDate($0.startDate, inSameDayAs: date)
                && $0.statusAgendaParticipante != Self.weeklyCheckInWithdrawnStatus
        }

        // Check-in formal (FezCheckin) do próprio aluno continua confirmando o dia
        if dayEntries.contains(where: \.hasCheckIn) {
            return .confirmed
        }

        // Sem identificador NextFit confiável não é possível verificar a lista de participantes
        guard identity.clientId != nil else {
            return .notConfirmed
        }

        // Somente aulas com participantes podem conter o aluno; aulas com
        // StatusAgendaParticipante informado (vínculo do aluno com a aula) são verificadas primeiro.
        let candidates = dayEntries
            .filter { $0.enrolledStudents > 0 }
            .sorted { lhs, rhs in
                (lhs.statusAgendaParticipante != nil) && (rhs.statusAgendaParticipante == nil)
            }

        var hasFailedLookup = false
        for entry in candidates where !verifiedAgendaIds.contains(entry.id) {
            if Task.isCancelled { return .indeterminate }
            let detail: NextFitAgendaDetailDisplay
            do {
                detail = try await nextFitService.loadAgendaDetail(
                    agendaId: entry.id,
                    sessionAccount: studentId
                )
            } catch NextFitServiceError.missingSession {
                throw NextFitServiceError.missingSession
            } catch NextFitServiceError.invalidSession {
                throw NextFitServiceError.invalidSession
            } catch {
                hasFailedLookup = true
                continue
            }

            // Desistência do aluno nesta aula não é participação confirmada
            if detail.statusAgendaParticipante == Self.weeklyCheckInWithdrawnStatus {
                verifiedAgendaIds.insert(entry.id)
                continue
            }
            if detail.hasCheckIn == true {
                return .confirmed
            }

            var hasUnverifiedParticipant = false
            for participant in detail.participants {
                switch try await isAuthenticatedStudent(participant, identity: &identity) {
                case true?:
                    return .confirmed
                case false?:
                    continue
                case nil:
                    hasUnverifiedParticipant = true
                }
            }
            if hasUnverifiedParticipant {
                hasFailedLookup = true
            } else {
                verifiedAgendaIds.insert(entry.id)
            }
        }

        return hasFailedLookup ? .indeterminate : .notConfirmed
    }

    /// Compara o participante com o aluno autenticado usando apenas identificadores NextFit
    /// (CodigoCliente e, na sua ausência, CodigoContratoCliente). Nunca compara nomes.
    /// Retorna `nil` quando não foi possível verificar (falha temporária).
    private func isAuthenticatedStudent(
        _ participant: NextFitAgendaParticipantDisplay,
        identity: inout WeeklyCheckInParticipantIdentity
    ) async throws -> Bool? {
        guard let clientId = identity.clientId else { return false }

        if let participantClientId = participant.clientId {
            return participantClientId == clientId
        }

        guard let participantContractId = participant.contractClientId else {
            return false
        }

        if identity.contractClientIds == nil {
            do {
                let clientData = try await nextFitService.loadClientMainData(sessionAccount: studentId)
                if clientData.clientId == clientId {
                    nextFitOwnContracts = (clientId, clientData.contracts)
                }
                // Usa os contratos somente se pertencerem ao mesmo cliente da sessão
                identity.contractClientIds = clientData.clientId == clientId
                    ? Set(clientData.contracts.map(\.id))
                    : []
            } catch NextFitServiceError.missingSession {
                throw NextFitServiceError.missingSession
            } catch NextFitServiceError.invalidSession {
                throw NextFitServiceError.invalidSession
            } catch {
                return nil
            }
        }

        return identity.contractClientIds?.contains(participantContractId) == true
    }

    // MARK: - Lembrete "Seu check-in de hoje" (exclusivo da Home do aluno)

    /// Carrega as aulas de hoje em que o aluno autenticado está confirmado na NextFit.
    /// Usa os mesmos critérios do resumo semanal (FezCheckin do próprio aluno ou o aluno na lista
    /// de participantes por CodigoCliente/CodigoContratoCliente; nunca por nome nem por quantidade
    /// de inscritos; desistência ignorada). Falhas nunca são tratadas como confirmação.
    func loadTodayConfirmedCheckIns() async {
        todayConfirmedCheckInsGeneration += 1
        let generation = todayConfirmedCheckInsGeneration

        guard nextFitService.hasSession(sessionAccount: studentId) else {
            todayConfirmedCheckIns = []
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        do {
            let agenda = try await nextFitService.loadAgenda(for: today, sessionAccount: studentId)
            guard !Task.isCancelled, generation == todayConfirmedCheckInsGeneration else { return }

            var identity = WeeklyCheckInParticipantIdentity(
                clientId: try? nextFitService.clientId(sessionAccount: studentId)
            )
            let dayEntries = agenda.filter {
                calendar.isDate($0.startDate, inSameDayAs: today)
                    && $0.statusAgendaParticipante != Self.weeklyCheckInWithdrawnStatus
            }

            var confirmed: [NextFitAgendaDisplay] = []
            for entry in dayEntries {
                if Task.isCancelled || generation != todayConfirmedCheckInsGeneration { return }

                // Check-in formal (FezCheckin) do próprio aluno
                if entry.hasCheckIn {
                    confirmed.append(entry)
                    continue
                }

                // Sem identificador NextFit confiável ou sem inscritos não há como o aluno constar na aula
                guard identity.clientId != nil, entry.enrolledStudents > 0 else { continue }

                let detail: NextFitAgendaDetailDisplay
                do {
                    detail = try await nextFitService.loadAgendaDetail(
                        agendaId: entry.id,
                        sessionAccount: studentId
                    )
                } catch NextFitServiceError.missingSession {
                    throw NextFitServiceError.missingSession
                } catch NextFitServiceError.invalidSession {
                    throw NextFitServiceError.invalidSession
                } catch {
                    // Falha temporária não confirma participação
                    continue
                }

                if detail.statusAgendaParticipante == Self.weeklyCheckInWithdrawnStatus {
                    continue
                }
                if detail.hasCheckIn == true {
                    confirmed.append(entry)
                    continue
                }
                for participant in detail.participants {
                    if try await isAuthenticatedStudent(participant, identity: &identity) == true {
                        confirmed.append(entry)
                        break
                    }
                }
            }

            guard !Task.isCancelled, generation == todayConfirmedCheckInsGeneration else { return }
            todayConfirmedCheckIns = confirmed.sorted { $0.startDate < $1.startDate }
        } catch {
            guard !Task.isCancelled, generation == todayConfirmedCheckInsGeneration else { return }
            // Sessão ausente/expirada ou falha na consulta: não exibe dados não confirmados
            todayConfirmedCheckIns = []
            #if DEBUG
            print("[StudentDashboard] Não foi possível carregar o check-in de hoje: \(error.localizedDescription)")
            #endif
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
            nextFitOwnContracts = nil
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
            #if DEBUG
            // Diagnóstico temporário da categoria dos participantes NextFit
            if let detail = selectedNextFitAgendaDetail {
                logNextFitParticipantCategories(detail)
            }
            #endif
            // Contratos do próprio aluno: carregados uma única vez por sessão, sem bloquear o detalhe
            if nextFitOwnContracts == nil {
                Task { await loadOwnNextFitContractsIfNeeded() }
            }
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
            let enteredWaitlist = try await nextFitService.checkInAgenda(
                agendaId: agendaId,
                contractClientId: contract.contractClientId,
                sessionAccount: studentId
            )

            // Fila de espera não é uma reserva confirmada: mantém o fluxo original de atualização.
            guard !enteredWaitlist else {
                await refreshNextFitAgenda(
                    afterActionFor: agendaId,
                    errorMessage: AppLocalization.string("dashboard.agenda.schedule_error", locale: locale),
                    locale: locale
                )
                return
            }

            // Check-in confirmado pelo NextFit: reflete imediatamente no horário e no detalhe abertos
            applyConfirmedAgendaCheckIn(agendaId)
            await reconcileNextFitAgendaAfterCheckIn(agendaId)
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

    /// Categoria comercial do participante para o ícone da lista (nunca derivada de `Status`).
    func nextFitParticipantCategory(_ participant: NextFitAgendaParticipantDisplay) -> NextFitParticipantCategory {
        resolveNextFitParticipantCategory(participant).category
    }

    private func resolveNextFitParticipantCategory(
        _ participant: NextFitAgendaParticipantDisplay
    ) -> NextFitParticipantCategoryResolution {
        NextFitParticipantCategoryResolver.resolve(
            participant: participant,
            ownContract: ownNextFitContractCommercialInfo(for: participant)
        )
    }

    /// Tipo do contrato próprio e `Modalidades[].Tipo` da modalidade da aula aberta (somente se
    /// houver exatamente um tipo para essa modalidade no contrato; caso contrário, `nil`).
    private func ownNextFitContractCommercialInfo(
        for participant: NextFitAgendaParticipantDisplay
    ) -> NextFitOwnContractCommercialInfo? {
        guard let contract = ownNextFitContract(for: participant) else { return nil }

        var modalityType: Int?
        if let agendaModalityId = selectedNextFitAgendaDetail?.modalityId {
            let types = Set(
                contract.modalities
                    .filter { $0.modalityId == agendaModalityId }
                    .compactMap { $0.type }
            )
            if types.count == 1 {
                modalityType = types.first
            }
        }
        return NextFitOwnContractCommercialInfo(contractType: contract.type, modalityType: modalityType)
    }

    /// Carrega uma única vez por sessão os contratos do próprio aluno autenticado (mesmo `CodigoCliente`
    /// do token da sessão) para a classificação dos participantes. Não altera check-in, cancelamento
    /// nem agendamento. Falhas são ignoradas: a classificação permanece `unknown`.
    private func loadOwnNextFitContractsIfNeeded() async {
        guard nextFitOwnContracts == nil,
              !isLoadingOwnNextFitContracts,
              hasNextFitSession,
              let clientId = try? nextFitService.clientId(sessionAccount: studentId) else {
            return
        }

        isLoadingOwnNextFitContracts = true
        defer { isLoadingOwnNextFitContracts = false }

        guard let clientData = try? await nextFitService.loadClientMainData(sessionAccount: studentId),
              clientData.clientId == clientId,
              hasNextFitSession,
              nextFitOwnContracts == nil else {
            #if DEBUG
            print("[NextFitCategoryDiag] CONTRATOS_PROPRIOS carga=indisponivel")
            #endif
            return
        }

        nextFitOwnContracts = (clientId, clientData.contracts)
        #if DEBUG
        print("[NextFitCategoryDiag] CONTRATOS_PROPRIOS carga=ok total=\(clientData.contracts.count)")
        if let detail = selectedNextFitAgendaDetail {
            logNextFitParticipantCategories(detail)
        }
        #endif
    }

    /// Contrato do próprio aluno autenticado vinculado ao participante por `CodigoContratoCliente`.
    /// Retorna `nil` para qualquer outro participante ou quando os contratos ainda não foram carregados.
    private func ownNextFitContract(
        for participant: NextFitAgendaParticipantDisplay
    ) -> NextFitClientMainDataResponse.Content.Contract? {
        guard let own = nextFitOwnContracts,
              let contractClientId = participant.contractClientId else {
            return nil
        }
        if let participantClientId = participant.clientId, participantClientId != own.clientId {
            return nil
        }
        return own.contracts.first { $0.id == contractClientId }
    }

    func logoutNextFit() throws {
        try nextFitService.logout(sessionAccount: studentId)
        nextFitContractClientIdsByModality = [:]
        nextFitOwnContracts = nil
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
        nextFitOwnContracts = nil
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

    // Atualiza somente o estado local do horário cujo check-in foi confirmado pelo NextFit
    private func applyConfirmedAgendaCheckIn(_ agendaId: Int) {
        if let index = nextFitAgenda.firstIndex(where: { $0.id == agendaId }) {
            let entry = nextFitAgenda[index]
            nextFitAgenda[index] = NextFitAgendaDisplay(
                id: entry.id,
                statusAgendaParticipante: entry.statusAgendaParticipante,
                startDate: entry.startDate,
                endDate: entry.endDate,
                startTime: entry.startTime,
                endTime: entry.endTime,
                enrolledStudents: entry.enrolledStudents,
                studentLimit: entry.studentLimit,
                modalityName: entry.modalityName,
                instructorName: entry.instructorName,
                locationName: entry.locationName,
                canSchedule: false,
                canCancelCheckIn: true,
                hasCheckIn: true
            )
        }

        if let detail = selectedNextFitAgendaDetail, detail.id == agendaId {
            selectedNextFitAgendaDetail = NextFitAgendaDetailDisplay(
                id: detail.id,
                statusAgendaParticipante: detail.statusAgendaParticipante,
                modalityId: detail.modalityId,
                hasCheckIn: true,
                canSchedule: false,
                canCancelCheckIn: true,
                dateText: detail.dateText,
                scheduleText: detail.scheduleText,
                capacityText: detail.capacityText,
                modalityName: detail.modalityName,
                instructorName: detail.instructorName,
                locationName: detail.locationName,
                participants: detail.participants
            )
        }
    }

    // Sincroniza com o NextFit após check-in confirmado, sem ocultar o detalhe aberto
    // e sem desfazer a confirmação caso apenas a atualização posterior falhe.
    private func reconcileNextFitAgendaAfterCheckIn(_ agendaId: Int) async {
        let agendaDate = selectedNextFitAgendaDate
        do {
            let refreshedAgenda = try await nextFitService.loadAgenda(
                for: agendaDate,
                sessionAccount: studentId
            )
            // Ignora a resposta se o aluno trocou de data durante a sincronização
            guard Calendar.current.isDate(selectedNextFitAgendaDate, inSameDayAs: agendaDate) else { return }
            nextFitAgenda = refreshedAgenda

            if selectedNextFitAgendaId == agendaId {
                let refreshedDetail = try await nextFitService.loadAgendaDetail(
                    agendaId: agendaId,
                    sessionAccount: studentId
                )
                if selectedNextFitAgendaId == agendaId {
                    selectedNextFitAgendaDetail = refreshedDetail
                }
            }
        } catch let error as NextFitServiceError {
            switch error {
            case .missingSession, .invalidSession:
                hasNextFitSession = false
                needsNextFitAuthentication = true
            default:
                // Check-in já confirmado: mantém o estado confirmado até a próxima atualização.
                break
            }
        } catch {
            // Check-in já confirmado: mantém o estado confirmado até a próxima atualização.
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
        nextFitOwnContracts = (clientId, clientData.contracts)

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

    private static var checkInWeekCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private static func currentCheckInWeekDates(calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let week = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        let weekStart = calendar.startOfDay(for: week.start)
        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    private static func makeCurrentWeekCheckInSummaries(
        checkedInDays: Set<Date>
    ) -> [StudentDashboardDaySummary] {
        let calendar = checkInWeekCalendar
        return currentCheckInWeekDates(calendar: calendar).map { date in
            StudentDashboardDaySummary(
                date: date,
                isCompleted: checkedInDays.contains { calendar.isDate($0, inSameDayAs: date) }
            )
        }
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

#if DEBUG
// MARK: - Diagnóstico temporário da categoria dos participantes NextFit (somente DEBUG — REMOVER após validação)
// Usa apenas dados já carregados. Não registra nomes, tokens, códigos de cliente ou de contrato.
extension StudentDashboardViewModel {
    fileprivate func logNextFitParticipantCategories(_ detail: NextFitAgendaDetailDisplay) {
        let prefix = "[NextFitCategoryDiag]"
        print("\(prefix) DETALHE agenda=\(detail.id) total=\(detail.participants.count) contratosProprios=\(nextFitOwnContracts == nil ? "indisponiveis" : "disponiveis")")

        if let own = nextFitOwnContracts {
            for (index, contract) in own.contracts.enumerated() {
                let hasDescription = !(contract.descriptionText?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
                // Somente a presença de `Descricao` (texto livre pode conter dados pessoais); sem regra validada
                let modalityTypes = contract.modalities.map { $0.type.map { String($0) } ?? "nil" }
                print("\(prefix) CONTRATO_PROPRIO #\(index + 1) Tipo=\(contract.type) Status=\(contract.status) modalidades=\(contract.modalities.count) tiposModalidade=\(modalityTypes) descricao=\(hasDescription ? "presente" : "ausente")")
            }
        }

        for (index, participant) in detail.participants.enumerated() {
            let resolution = resolveNextFitParticipantCategory(participant)
            let ownContract = ownNextFitContract(for: participant)
            var parts: [String] = []
            parts.append("\(prefix) PARTICIPANTE agenda=\(detail.id) #\(index + 1)")
            parts.append("Tipo=\(participant.type.map { String($0) } ?? "nil")")
            parts.append("Status=\(participant.status.map { String($0) } ?? "nil")")
            parts.append("Origem=\(participant.origin.map { String($0) } ?? "nil")")
            parts.append("contrato=\(participant.contractClientId == nil ? "ausente" : "presente")")
            if let own = nextFitOwnContracts {
                let isOwnClient = participant.clientId == own.clientId || ownContract != nil
                parts.append("aluno=\(isOwnClient ? "sim" : "nao")")
            }
            parts.append("proprio=\(ownContract == nil ? "nao" : "sim")")
            if let info = ownNextFitContractCommercialInfo(for: participant) {
                parts.append("contratoProprioTipo=\(info.contractType) modalidadeAulaTipo=\(info.modalityType.map { String($0) } ?? "nil")")
            }
            parts.append("categoria=\(resolution.category)")
            parts.append("motivo=\(resolution.reason)")
            parts.append("icone=\(resolution.category.symbolName)")
            print(parts.joined(separator: " "))
        }
    }
}
#endif


import Foundation
import Combine

enum StudentWorkoutDayStatus {
    case completed
    case overdue
    case pending
}

@MainActor
final class StudentWorkoutsViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var hasLoadedWeekMetadata: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var teacherNameById: [String: String] = [:]
    @Published private(set) var daysByWeekId: [String: [TrainingDayFS]] = [:]
    @Published private(set) var completedDayIdsByWeekId: [String: Set<String>] = [:]
    @Published private(set) var loadingWeekIds = Set<String>()
    @Published private(set) var weekDaysErrorByWeekId: [String: String] = [:]

    private var hasLoadedWeeksAndMeta: Bool = false
    private var weeksLoadTask: Task<Void, Never>?
    private var weekDaysLoadTasks: [String: Task<Void, Never>] = [:]
    private var metadataGeneration = UUID()

    var hasLoadedWeeks: Bool { hasLoadedWeeksAndMeta }

    private var weekRangeText: [String: String] = [:]
    @Published private(set) var weekProgressPercent: [String: Int] = [:]
    private var weekEndDate: [String: Date] = [:]

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    // MARK: - Semanas / Meta

    func loadWeeksAndMeta(
        force: Bool = false,
        filterByActiveTeacherLinks: Bool,
        viewingTeacherId: String? = nil
    ) async {
        if let task = weeksLoadTask {
            await task.value
            return
        }

        guard force || !hasLoadedWeeksAndMeta else { return }

        isLoading = true
        errorMessage = nil

        let task = Task { [weak self] in
            guard let self else { return }
            await self.performWeeksLoad(
                filterByActiveTeacherLinks: filterByActiveTeacherLinks,
                viewingTeacherId: viewingTeacherId
            )
        }
        weeksLoadTask = task
        await task.value
        weeksLoadTask = nil
    }

    private func performWeeksLoad(
        filterByActiveTeacherLinks: Bool,
        viewingTeacherId: String?
    ) async {
        do {
            #if DEBUG
            let t0 = Date()
            #endif

            let activeTeacherIds: Set<String>
            if filterByActiveTeacherLinks {
                activeTeacherIds = Set(
                    try await repository.getTeacherLinksForStudent(studentId: studentId)
                        .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            } else {
                activeTeacherIds = []
            }
            let cleanViewingTeacherId = viewingTeacherId?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let cleanViewingTeacherId, cleanViewingTeacherId.isEmpty {
                throw FirestoreRepositoryError.missingTeacherId
            }

            let result = try await repository.getWeeksForStudent(
                studentId: studentId,
                teacherId: cleanViewingTeacherId
            )
            let visibleWeeks = filterByActiveTeacherLinks
                ? result.filter {
                    activeTeacherIds.contains(
                        $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                : result

            #if DEBUG
            print("[StudentWorkouts] getWeeksForStudent: \(String(format: "%.2f", Date().timeIntervalSince(t0)))s — \(visibleWeeks.count) semana(s)")
            #endif

            // ✅ Publica semanas e encerra o loading principal imediatamente.
            // Metadados secundários (nomes de professor, datas, progresso) chegam
            // progressivamente sem bloquear a exibição da lista.
            self.weeks = visibleWeeks
            hasLoadedWeeksAndMeta = true
            hasLoadedWeekMetadata = visibleWeeks.isEmpty
            isLoading = false
            weekRangeText = [:]
            weekProgressPercent = [:]
            weekEndDate = [:]

            // Os metadados não atrasam a lista principal de semanas.
            let generation = UUID()
            metadataGeneration = generation
            Task { [weak self] in
                guard let self else { return }
                await self.loadSecondaryMetadata(for: visibleWeeks, generation: generation)
            }
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
            isLoading = false
        }
    }

    private func loadSecondaryMetadata(for weeks: [TrainingWeekFS], generation: UUID) async {
        #if DEBUG
        let t0 = Date()
        #endif

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTeacherNamesForWeeks(weeks, generation: generation) }
            group.addTask { await self.loadMetaForWeeks(weeks, generation: generation) }
        }

        #if DEBUG
        print("[StudentWorkouts] metadata completo em \(String(format: "%.2f", Date().timeIntervalSince(t0)))s — \(weeks.count * 2) reads auxiliares")
        #endif
    }

    private func loadTeacherNamesForWeeks(_ weeks: [TrainingWeekFS], generation: UUID) async {

        let ids = Array(
            Set(
                weeks
                    .filter {
                        let name = ($0.teacherName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        let email = ($0.teacherEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        return name.isEmpty && email.isEmpty
                    }
                    .map { $0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )

        guard !ids.isEmpty else { return }

        let repo = repository
        var result: [String: String] = [:]

        await withTaskGroup(of: (String, String?).self) { group in
            for teacherId in ids {
                group.addTask {
                    do {
                        let user = try await repo.getUser(uid: teacherId)
                        let name = user?.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        return (teacherId, (name?.isEmpty == false) ? name : nil)
                    } catch {
                        return (teacherId, nil)
                    }
                }
            }

            for await (teacherId, name) in group {
                if let name {
                    result[teacherId] = name
                }
            }
        }

        guard metadataGeneration == generation else { return }
        teacherNameById.merge(result, uniquingKeysWith: { _, new in new })
    }

    private func loadMetaForWeeks(_ weeks: [TrainingWeekFS], generation: UUID) async {

        await withTaskGroup(of: Void.self) { group in
            for week in weeks {
                guard let weekId = week.id, !weekId.isEmpty else { continue }

                group.addTask {
                    await self.loadCachedMetadata(for: week, generation: generation)
                }
            }
        }

        if metadataGeneration == generation {
            hasLoadedWeekMetadata = true
            objectWillChange.send()
        }
    }

    private func loadCachedMetadata(for week: TrainingWeekFS, generation: UUID) async {
        guard let weekId = week.id else { return }
        await loadDaysAndStatus(for: weekId)
        guard metadataGeneration == generation,
              daysError(for: weekId) == nil else {
            return
        }

        if let range = Self.computeRangeTextStatic(startDate: week.startDate, endDate: week.endDate) {
            weekRangeText[weekId] = range
        }
        if let endDate = week.endDate {
            weekEndDate[weekId] = endDate
        }
        let days = days(for: weekId)

        let trainingDays = days.filter { !$0.isVideoDay }
        let completed = trainingDays.compactMap(\.id)
            .filter { isCompleted(dayId: $0, in: weekId) }
            .count
        weekProgressPercent[weekId] = Self.computePercentStatic(
            completed: completed,
            total: trainingDays.count
        )
    }

    func subtitleForWeek(_ week: TrainingWeekFS) -> String {
        guard let weekId = week.id else { return "Treinos da semana" }

        let range = weekRangeText[weekId] ?? "Treinos da semana"

        return range
    }

    func teacherLineForWeek(_ week: TrainingWeekFS) -> String {
        let explicitName = (week.teacherName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicitName.isEmpty {
            return "Professor: \(explicitName)"
        }

        let explicitEmail = (week.teacherEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !explicitEmail.isEmpty {
            return "Professor: \(explicitEmail)"
        }

        let teacherId = week.teacherId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !teacherId.isEmpty else { return "Professor: —" }

        if let name = teacherNameById[teacherId], !name.isEmpty {
            return "Professor: \(name)"
        }

        return "Professor: ..."
    }

    func progressPercent(for week: TrainingWeekFS) -> Int {
        guard let weekId = week.id else { return 0 }
        return weekProgressPercent[weekId] ?? 0
    }

    func endDate(for week: TrainingWeekFS) -> Date? {
        guard let weekId = week.id else { return nil }
        return weekEndDate[weekId]
    }

    func isCompleted(_ week: TrainingWeekFS) -> Bool {
        progressPercent(for: week) >= 100
    }

    func isExpired(_ week: TrainingWeekFS, now: Date = Date()) -> Bool {
        guard let endDate = endDate(for: week) else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: endDate) < calendar.startOfDay(for: now)
    }

    func isUpcoming(_ week: TrainingWeekFS, now: Date = Date()) -> Bool {
        guard let startDate = week.startDate else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: startDate) > calendar.startOfDay(for: now)
    }

    func days(for weekId: String) -> [TrainingDayFS] {
        daysByWeekId[weekId] ?? []
    }

    func isLoadingDays(for weekId: String) -> Bool {
        loadingWeekIds.contains(weekId)
    }

    func daysError(for weekId: String) -> String? {
        weekDaysErrorByWeekId[weekId]
    }

    func isCompleted(dayId: String, in weekId: String) -> Bool {
        completedDayIdsByWeekId[weekId]?.contains(dayId) == true
    }

    func dayStatus(
        for days: [TrainingDayFS],
        in weekId: String,
        now: Date = Date()
    ) -> StudentWorkoutDayStatus {
        let dayIds = days.compactMap(\.id)
        guard !dayIds.isEmpty, dayIds.count == days.count else {
            return .pending
        }

        if dayIds.allSatisfy({ isCompleted(dayId: $0, in: weekId) }) {
            return .completed
        }

        return days.contains { isOverdue($0, in: weekId, now: now) } ? .overdue : .pending
    }

    func isOverdue(
        _ day: TrainingDayFS,
        in weekId: String,
        now: Date = Date()
    ) -> Bool {
        guard let date = day.date,
              let dayId = day.id,
              !isCompleted(dayId: dayId, in: weekId) else {
            return false
        }

        let calendar = Calendar.current
        return calendar.startOfDay(for: date) < calendar.startOfDay(for: now)
    }

    func loadDaysAndStatus(for weekId: String, force: Bool = false) async {
        guard !weekId.isEmpty else { return }
        if let task = weekDaysLoadTasks[weekId] {
            await task.value
            return
        }
        guard force || daysByWeekId[weekId] == nil else { return }

        let task = Task { [weak self] in
            guard let self else { return }
            self.loadingWeekIds.insert(weekId)
            self.weekDaysErrorByWeekId.removeValue(forKey: weekId)
            defer {
                self.loadingWeekIds.remove(weekId)
                self.weekDaysLoadTasks.removeValue(forKey: weekId)
            }

            do {
                async let loadedDays = self.repository.getDaysForWeek(weekId: weekId)
                async let statusMap = self.repository.getDayStatusMap(
                    weekId: weekId,
                    studentId: self.studentId
                )
                let (days, statuses) = try await (loadedDays, statusMap)
                self.daysByWeekId[weekId] = days
                self.completedDayIdsByWeekId[weekId] = Set(
                    statuses.compactMap { $0.value ? $0.key : nil }
                )
            } catch {
                self.weekDaysErrorByWeekId[weekId] = (error as NSError).localizedDescription
            }
        }
        weekDaysLoadTasks[weekId] = task
        await task.value
    }

    func toggleCompleted(dayId: String, in weekId: String) async {
        guard let week = weeks.first(where: { $0.id == weekId }),
              let startDate = week.startDate else {
            weekDaysErrorByWeekId[weekId] = "Não foi possível validar o início desta semana."
            return
        }
        guard Calendar.current.startOfDay(for: Date()) >= Calendar.current.startOfDay(for: startDate) else {
            weekDaysErrorByWeekId[weekId] = FirestoreRepositoryError.weekNotStarted.localizedDescription
            return
        }

        let newValue = !isCompleted(dayId: dayId, in: weekId)

        do {
            try await repository.setDayCompleted(
                weekId: weekId,
                studentId: studentId,
                dayId: dayId,
                completed: newValue
            )

            var completed = completedDayIdsByWeekId[weekId] ?? []
            if newValue {
                completed.insert(dayId)
            } else {
                completed.remove(dayId)
            }
            completedDayIdsByWeekId[weekId] = completed

            if let days = daysByWeekId[weekId] {
                let trainingDays = days.filter { !$0.isVideoDay }
                weekProgressPercent[weekId] = Self.computePercentStatic(
                    completed: trainingDays.compactMap(\.id).filter { completed.contains($0) }.count,
                    total: trainingDays.count
                )
            }
        } catch {
            weekDaysErrorByWeekId[weekId] = (error as NSError).localizedDescription
        }
    }

    nonisolated static func computePercentStatic(completed: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let v = (Double(completed) / Double(total)) * 100.0
        return Int(v.rounded())
    }

    nonisolated static func computeRangeTextStatic(startDate: Date?, endDate: Date?) -> String? {
        guard let startDate, let endDate else { return nil }

        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy"

        return "\(f.string(from: startDate)) a \(f.string(from: endDate))"
    }
}

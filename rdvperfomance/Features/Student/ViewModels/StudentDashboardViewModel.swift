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
    @Published private(set) var currentWeekDaySummaries: [StudentDashboardDaySummary] = []
    @Published private(set) var upcomingDayGroups: [StudentDashboardDayGroup] = []
    @Published private(set) var isLoading = true
    @Published private(set) var teacherLinkState: StudentDashboardTeacherLinkState = .loading
    @Published private(set) var pendingTeacherInvites: [TeacherStudentInviteFS] = []

    private let studentId: String
    private let repository: FirestoreRepository
    private var isLoadingData = false

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    func load() async {
        guard !isLoadingData else { return }
        isLoadingData = true
        isLoading = true
        teacherLinkState = .loading
        defer {
            isLoadingData = false
            isLoading = false
        }
        async let pendingInvites: Void = loadPendingTeacherInvites()

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

        guard !activeTeacherIds.isEmpty else {
            currentWeekDaySummaries = []
            upcomingDayGroups = []
            _ = await pendingInvites
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

        _ = await pendingInvites
    }

    private func loadPendingTeacherInvites() async {
        do {
            guard let student = try await repository.getUser(uid: studentId) else {
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
                    $0.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pending"
                }
        } catch {
            pendingTeacherInvites = []
        }
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

import Foundation
import Combine

struct StudentDashboardDay: Identifiable {
    let weekId: String
    let weekTitle: String
    let day: TrainingDayFS
    let isCompleted: Bool

    var id: String { "\(weekId)-\(day.id ?? day.dayIndex.description)" }
}

@MainActor
final class StudentDashboardViewModel: ObservableObject {
    @Published private(set) var currentWeekDays: [StudentDashboardDay] = []
    @Published private(set) var upcomingDays: [StudentDashboardDay] = []
    @Published private(set) var isLoading = true

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
        defer {
            isLoadingData = false
            isLoading = false
        }

        do {
            let weeks = try await repository.getWeeksForStudent(studentId: studentId)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let data = try await loadDays(for: weeks)
            let currentWeek = weeks
                .filter { contains(today, in: $0, calendar: calendar) }
                .sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }
                .first

            currentWeekDays = data
                .filter { $0.weekId == currentWeek?.id }
                .sorted { ($0.day.date ?? .distantFuture) < ($1.day.date ?? .distantFuture) }
            upcomingDays = data
                .filter {
                    guard let date = $0.day.date else { return false }
                    return date >= today && !$0.isCompleted
                }
                .sorted { ($0.day.date ?? .distantFuture) < ($1.day.date ?? .distantFuture) }
                .prefix(3)
                .map { $0 }
        } catch {
            #if DEBUG
            print("[StudentDashboard] Não foi possível carregar a Home: \(error.localizedDescription)")
            #endif
            currentWeekDays = []
            upcomingDays = []
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

    private func contains(_ date: Date, in week: TrainingWeekFS, calendar: Calendar) -> Bool {
        guard let startDate = week.startDate else { return false }
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(
            for: week.endDate ?? calendar.date(byAdding: .day, value: 6, to: start) ?? start
        )
        return date >= start && date <= end
    }
}

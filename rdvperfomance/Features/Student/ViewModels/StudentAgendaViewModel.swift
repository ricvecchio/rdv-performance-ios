import Foundation
import Combine

@MainActor
final class StudentAgendaViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // weekId -> "12/01/2026 a 14/01/2026"
    private var weekRangeText: [String: String] = [:]

    // weekId -> 35
    private var weekProgressPercent: [String: Int] = [:]

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

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

        // ✅ limpa cache antes de recarregar (garante atualização)
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
                        // fallback silencioso
                    }
                }
            }
        }

        // força refresh da lista
        objectWillChange.send()
    }

    func subtitleForWeek(_ week: TrainingWeekFS) -> String {
        guard let weekId = week.id else { return "Treinos da semana" }

        let range = weekRangeText[weekId] ?? "Treinos da semana"
        let percent = weekProgressPercent[weekId] ?? 0

        return "\(range) • \(percent)%"
    }

    // ✅ STATIC / NON-ACTOR helpers
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

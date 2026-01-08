import Foundation
import Combine

@MainActor
final class StudentWeekDetailViewModel: ObservableObject {

    @Published private(set) var days: [TrainingDayFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var completedDayIds: Set<String> = []

    private let weekId: String
    private let studentId: String
    private let repository: FirestoreRepository

    init(weekId: String, studentId: String, repository: FirestoreRepository) {
        self.weekId = weekId
        self.studentId = studentId
        self.repository = repository
    }

    // Carrega dias da semana e status de conclusão
    func loadDaysAndStatus() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await repository.getDaysForWeek(weekId: weekId)
            self.days = result

            let statusMap = try await repository.getDayStatusMap(weekId: weekId, studentId: studentId)

            let completed = statusMap.compactMap { pair -> String? in
                pair.value ? pair.key : nil
            }

            self.completedDayIds = Set(completed)

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }
    }

    // Verifica se dia está marcado como concluído
    func isCompleted(dayId: String) -> Bool {
        completedDayIds.contains(dayId)
    }

    // Alterna status de conclusão de um dia
    func toggleCompleted(dayId: String) async {
        let newValue = !isCompleted(dayId: dayId)

        do {
            try await repository.setDayCompleted(
                weekId: weekId,
                studentId: studentId,
                dayId: dayId,
                completed: newValue
            )

            if newValue {
                completedDayIds.insert(dayId)
            } else {
                completedDayIds.remove(dayId)
            }

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }
    }
}

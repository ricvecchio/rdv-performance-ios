import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class CreateTrainingWeekViewModel: ObservableObject {

    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    // Carrega semanas do aluno incluindo rascunhos
    func loadWeeks(studentId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId, onlyPublished: false)

            self.weeks = result.sorted { a, b in
                let ad = a.createdAt?.dateValue() ?? Date.distantPast
                let bd = b.createdAt?.dateValue() ?? Date.distantPast
                return ad > bd
            }

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    // Atualiza ranges de datas das semanas baseado nos dias
    func repairWeekRangesIfNeeded() async {
        let ids = weeks.compactMap { $0.id }
        guard !ids.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for weekId in ids {
                group.addTask {
                    do {
                        try await FirestoreRepository.shared.updateWeekDateRangeFromDays(weekId: weekId)
                    } catch {
                    }
                }
            }
        }

        do {
            let result = try await repository.getWeeksForStudent(studentId: studentId, onlyPublished: false)
            self.weeks = result.sorted { a, b in
                let ad = a.createdAt?.dateValue() ?? Date.distantPast
                let bd = b.createdAt?.dateValue() ?? Date.distantPast
                return ad > bd
            }
        } catch {
        }
    }
}

// CreateTrainingWeekViewModel.swift — ViewModel para carregar e reparar semanas de treino de um aluno
import Foundation
import Combine
import FirebaseFirestore

// MARK: - ViewModel
@MainActor
final class CreateTrainingWeekViewModel: ObservableObject {

    // Semanas do aluno
    @Published private(set) var weeks: [TrainingWeekFS] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let studentId: String
    private let repository: FirestoreRepository

    init(studentId: String, repository: FirestoreRepository) {
        self.studentId = studentId
        self.repository = repository
    }

    // Carrega semanas (inclui rascunhos)
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

    // Repara ranges de semanas a partir dos dias, se necessário
    func repairWeekRangesIfNeeded() async {
        let ids = weeks.compactMap { $0.id }
        guard !ids.isEmpty else { return }

        await withTaskGroup(of: Void.self) { group in
            for weekId in ids {
                group.addTask {
                    do {
                        try await FirestoreRepository.shared.updateWeekDateRangeFromDays(weekId: weekId)
                    } catch {
                        // fallback silencioso
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
            // mantém lista atual
        }
    }
}

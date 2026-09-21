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
    func loadWeeks(studentId: String, teacherId: String, categoryRaw: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getWeeksForStudent(
                studentId: studentId,
                teacherId: teacherId,
                categoryRaw: categoryRaw,
                onlyPublished: false
            )

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

}

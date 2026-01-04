import Foundation
import Combine

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var isUnlinking: Bool = false

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    func loadStudents(teacherId: String, selectedCategory: TreinoTipo) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: selectedCategory.rawValue
            )
            self.students = result
        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    func filteredStudents(filter: TreinoTipo?) -> [AppUser] {
        guard let filter else { return students }
        let key = filter.rawValue.lowercased()
        return students.filter { ($0.defaultCategory ?? "").lowercased() == key }
    }

    func unlinkStudent(
        teacherId: String,
        studentId: String,
        category: String,
        selectedCategory: TreinoTipo
    ) async {
        isUnlinking = true
        errorMessage = nil

        do {
            try await repository.unlinkStudentFromTeacher(
                teacherId: teacherId,
                studentId: studentId,
                category: category
            )

            // Recarrega lista para refletir a remoção
            let result = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: selectedCategory.rawValue
            )
            self.students = result

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isUnlinking = false
    }
}


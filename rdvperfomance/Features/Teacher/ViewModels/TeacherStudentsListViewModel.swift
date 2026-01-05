// TeacherStudentsListViewModel.swift — ViewModel para gerenciar a lista de alunos do professor
import Foundation
import Combine

@MainActor
final class TeacherStudentsListViewModel: ObservableObject {

    // Lista unificada de alunos e estados
    @Published private(set) var students: [AppUser] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var isUnlinking: Bool = false

    private let repository: FirestoreRepository

    // Cache por categoria e categorias suportadas
    private var studentsByCategory: [TreinoTipo: [AppUser]] = [:]
    private let supportedCategories: [TreinoTipo] = [.crossfit, .academia, .emCasa]

    init(repository: FirestoreRepository) {
        self.repository = repository
    }

    // Carrega alunos de todas as categorias em paralelo
    func loadStudents(teacherId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let results = try await withThrowingTaskGroup(of: (TreinoTipo, [AppUser]).self) { group in
                for cat in supportedCategories {
                    group.addTask {
                        let list = try await self.repository.getStudentsForTeacher(
                            teacherId: teacherId,
                            category: cat.rawValue
                        )
                        return (cat, list)
                    }
                }

                var collected: [(TreinoTipo, [AppUser])] = []
                for try await item in group { collected.append(item) }
                return collected
            }

            var map: [TreinoTipo: [AppUser]] = [:]
            for (cat, list) in results { map[cat] = list }
            self.studentsByCategory = map
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { map[$0] })

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
            self.studentsByCategory = [:]
            self.students = []
        }

        isLoading = false
    }

    // Carrega apenas uma categoria (usado pelo HomeView)
    func loadStudentsOnlyOneCategory(teacherId: String, category: TreinoTipo) async {
        isLoading = true
        errorMessage = nil

        do {
            let list = try await repository.getStudentsForTeacher(
                teacherId: teacherId,
                category: category.rawValue
            )

            studentsByCategory[category] = list
            self.students = mergeUniqueStudents(from: supportedCategories.compactMap { studentsByCategory[$0] })

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isLoading = false
    }

    // Retorna alunos filtrados por categoria
    func filteredStudents(filter: TreinoTipo?) -> [AppUser] {
        guard let filter else { return students }
        return studentsByCategory[filter] ?? []
    }

    // Desvincula um aluno (por categoria ou todas)
    func unlinkStudent(
        teacherId: String,
        studentId: String,
        categoryToRemove: TreinoTipo?
    ) async {
        isUnlinking = true
        errorMessage = nil

        do {
            if let cat = categoryToRemove {
                try await repository.unlinkStudentFromTeacher(
                    teacherId: teacherId,
                    studentId: studentId,
                    category: cat.rawValue
                )
            } else {
                let catsToRemove = categoriesWhereStudentIsLinked(studentId: studentId)
                let effective = catsToRemove.isEmpty ? supportedCategories : catsToRemove

                for cat in effective {
                    do {
                        try await repository.unlinkStudentFromTeacher(
                            teacherId: teacherId,
                            studentId: studentId,
                            category: cat.rawValue
                        )
                    } catch {
                        continue
                    }
                }
            }

            await loadStudents(teacherId: teacherId)

        } catch {
            self.errorMessage = (error as NSError).localizedDescription
        }

        isUnlinking = false
    }

    // Retorna categorias onde o aluno está vinculado
    private func categoriesWhereStudentIsLinked(studentId: String) -> [TreinoTipo] {
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sid.isEmpty else { return [] }

        return supportedCategories.filter { cat in
            let list = studentsByCategory[cat] ?? []
            return list.contains(where: { ($0.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == sid })
        }
    }

    // Une listas removendo duplicados
    private func mergeUniqueStudents(from lists: [[AppUser]]) -> [AppUser] {
        var seen: Set<String> = []
        var merged: [AppUser] = []

        for list in lists {
            for u in list {
                let key = uniqueKey(for: u)
                if seen.contains(key) { continue }
                seen.insert(key)
                merged.append(u)
            }
        }

        return merged.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // Chave única baseada em id, ou nome+email
    private func uniqueKey(for user: AppUser) -> String {
        if let id = user.id, !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return id
        }
        let name = user.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let email = (user.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(name)|\(email)"
    }
}

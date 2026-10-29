import SwiftUI
import Combine

/// Estado observável e compartilhado que define se a aba "Treinos" está disponível no rodapé do aluno.
///
/// Regra (a mesma da Home, `StudentDashboardViewModel`): o aluno é considerado vinculado quando
/// `getTeacherLinksForStudent(studentId:)` retorna ao menos um professor (relação ativa;
/// convites pendentes ficam em outra coleção e não contam).
///
/// - `.loading` e `.failed` NUNCA escondem Treinos (sem resultado confiável a aba é preservada).
/// - Somente `.unlinked` (ausência confirmada) substitui Treinos por Lembretes.
/// - Uma falha após um resultado confiável preserva o último resultado confirmado.
@MainActor
final class StudentTabsState: ObservableObject {

    @Published private(set) var teacherLinkState: StudentDashboardTeacherLinkState = .loading

    private var isRefreshing = false
    private var needsAnotherRefresh = false
    private var trackedStudentId = ""

    var showsWorkouts: Bool { teacherLinkState != .unlinked }

    /// Reconsulta os vínculos. Chamadas simultâneas são coalescidas em uma consulta extra.
    func refresh(studentId: String, repository: FirestoreRepository = .shared) async {
        let sid = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sid.isEmpty else { return }

        if trackedStudentId != sid {
            trackedStudentId = sid
            teacherLinkState = .loading
        }

        if isRefreshing {
            needsAnotherRefresh = true
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            needsAnotherRefresh = false
            do {
                let links = try await repository.getTeacherLinksForStudent(studentId: sid)
                let hasActiveTeacher = links.contains {
                    !$0.teacherId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }
                teacherLinkState = hasActiveTeacher ? .linked : .unlinked
            } catch {
                // Falha não é ausência de vínculo: mantém o último resultado confirmado.
                if teacherLinkState == .loading {
                    teacherLinkState = .failed
                }
            }
        } while needsAnotherRefresh
    }
}

private struct StudentShowsWorkoutsKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Disponibilidade da aba Treinos no rodapé do aluno (padrão `true` fora do contexto do aluno).
    var studentShowsWorkoutsTab: Bool {
        get { self[StudentShowsWorkoutsKey.self] }
        set { self[StudentShowsWorkoutsKey.self] = newValue }
    }
}


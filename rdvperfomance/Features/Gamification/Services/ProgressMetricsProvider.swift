import Foundation

/// Provedor responsável por carregar métricas de progresso em diferentes modos
final class ProgressMetricsProvider {

    /// Repositório Firestore para acesso aos dados
    private let repository: FirestoreRepository

    /// Inicializa o provider com repositório específico ou shared por padrão
    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    /// Carrega métricas mock para modo preview sem necessidade de rede
    func loadPreview() async -> ProgressMetrics {
        ProgressMetricsMock.random()
    }

    /// Carrega métricas de aluno específico para visualização do professor
    func loadForTeacher(studentId: String, displayName: String?) async -> ProgressMetrics {
        do {
            /// Busca progresso geral do aluno no repositório
            let overall = try await repository.getStudentOverallProgress(studentId: studentId)
            let completion = max(0.0, min(1.0, Double(overall.percent) / 100.0))

            let streak = estimateStreak(fromPercent: overall.percent)
            let badges = badgesFor(percent: overall.percent)

            return ProgressMetrics(
                weeklyCompletion: completion,
                streakDays: streak,
                badges: badges,
                displayName: displayName,
                weekLabel: "Progresso geral"
            )
        } catch {
            /// Retorna métricas vazias em caso de erro para garantir falha segura
            return ProgressMetrics(
                weeklyCompletion: 0.0,
                streakDays: 0,
                badges: [],
                displayName: displayName,
                weekLabel: "Progresso geral"
            )
        }
    }

    /// Carrega métricas do próprio aluno logado reutilizando estratégia do professor
    func loadForStudentMe(studentId: String, displayName: String?) async -> ProgressMetrics {
        await loadForTeacher(studentId: studentId, displayName: displayName)
    }

    /// Estima quantidade de dias consecutivos baseado no percentual de progresso
    private func estimateStreak(fromPercent percent: Int) -> Int {
        switch percent {
        case ..<1:
            return 0
        case 1...20:
            return 1
        case 21...40:
            return 3
        case 41...60:
            return 5
        case 61...80:
            return 7
        case 81...95:
            return 10
        default:
            return 14
        }
    }

    /// Retorna lista de badges conquistadas baseado no percentual de progresso
    private func badgesFor(percent: Int) -> [Badge] {
        var list: [Badge] = []

        if percent > 0 {
            list.append(Badge(id: "b1", title: "Primeiro treino", systemImageName: "sparkles"))
        }
        if percent >= 40 {
            list.append(Badge(id: "b2", title: "3 treinos/semana", systemImageName: "dumbbell.fill"))
        }
        if percent >= 80 {
            list.append(Badge(id: "b3", title: "Consistência", systemImageName: "bolt.fill"))
        }
        if percent >= 100 {
            list.append(Badge(id: "b4", title: "Semana completa", systemImageName: "checkmark.seal.fill"))
        }

        return list
    }
}

import Foundation

// MARK: - ProgressMetricsProvider
// Fornece métricas para preview / aluno / professor.
// Boa prática: separar "obter dados" da UI.
final class ProgressMetricsProvider {

    private let repository: FirestoreRepository

    init(repository: FirestoreRepository = .shared) {
        self.repository = repository
    }

    // Preview sempre funciona sem rede
    func loadPreview() async -> ProgressMetrics {
        ProgressMetricsMock.random()
    }

    // Professor visualiza aluno específico
    func loadForTeacher(studentId: String, displayName: String?) async -> ProgressMetrics {
        // MVP seguro: usa o progresso geral já existente no repositório.
        // Streak/badges podem ser heurísticas por enquanto.
        do {
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
            // Falha segura
            return ProgressMetrics(
                weeklyCompletion: 0.0,
                streakDays: 0,
                badges: [],
                displayName: displayName,
                weekLabel: "Progresso geral"
            )
        }
    }

    // Aluno logado (se você quiser reutilizar depois)
    func loadForStudentMe(studentId: String, displayName: String?) async -> ProgressMetrics {
        // Reutiliza a mesma estratégia do professor
        await loadForTeacher(studentId: studentId, displayName: displayName)
    }

    // MARK: - Helpers (heurísticas simples para MVP)
    private func estimateStreak(fromPercent percent: Int) -> Int {
        // Heurística simples:
        // 0-20% => 1
        // 21-60% => 3-6
        // 61-100% => 7-14
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

    private func badgesFor(percent: Int) -> [Badge] {
        var list: [Badge] = []

        if percent > 0 {
            list.append(Badge(id: "b1", title: "Primeiro treino", systemImageName: "sparkles"))
        }
        if percent >= 40 {
            list.append(Badge(id: "b2", title: "3 treinos/semana", systemImageName: "flame.fill"))
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

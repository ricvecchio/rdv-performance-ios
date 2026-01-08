import Foundation

/// Fornece cenários mock de métricas de progresso para demos e testes
enum ProgressMetricsMock {

    /// Retorna métricas de usuário iniciante com progresso mínimo
    static func beginner() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 0.20,
            streakDays: 1,
            badges: [
                Badge(id: "b1", title: "Primeiro treino", systemImageName: "sparkles")
            ],
            displayName: "Aluno (preview)",
            weekLabel: "Semana atual"
        )
    }

    /// Retorna métricas de usuário consistente com bom progresso
    static func consistent() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 0.75,
            streakDays: 6,
            badges: [
                Badge(id: "b1", title: "Primeiro treino", systemImageName: "sparkles"),
                Badge(id: "b2", title: "3 treinos/semana", systemImageName: "flame.fill")
            ],
            displayName: "Aluno consistente",
            weekLabel: "Semana atual"
        )
    }

    /// Retorna métricas de usuário expert com progresso máximo
    static func beastMode() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 1.0,
            streakDays: 14,
            badges: [
                Badge(id: "b1", title: "Primeiro treino", systemImageName: "sparkles"),
                Badge(id: "b2", title: "3 treinos/semana", systemImageName: "flame.fill"),
                Badge(id: "b3", title: "Semana completa", systemImageName: "checkmark.seal.fill")
            ],
            displayName: "Modo monstro",
            weekLabel: "Semana atual"
        )
    }

    /// Retorna métricas aleatórias entre os cenários disponíveis
    static func random() -> ProgressMetrics {
        let options = [beginner(), consistent(), beastMode()]
        return options.randomElement() ?? beginner()
    }
}

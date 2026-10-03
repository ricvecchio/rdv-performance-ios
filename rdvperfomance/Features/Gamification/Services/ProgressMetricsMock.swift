import Foundation

/// Fornece cenários mock de métricas de progresso para demos e testes
enum ProgressMetricsMock {

    /// Retorna métricas de usuário iniciante com progresso mínimo
    static func beginner() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 0.20,
            streakDays: 1,
            badges: [
                Badge(id: "b1", systemImageName: "sparkles")
            ],
            displayName: nil,
            displayNameCopy: .previewStudent,
            weekLabel: nil,
            weekLabelCopy: .currentWeek
        )
    }

    /// Retorna métricas de usuário consistente com bom progresso
    static func consistent() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 0.75,
            streakDays: 6,
            badges: [
                Badge(id: "b1", systemImageName: "sparkles"),
                Badge(id: "b2", systemImageName: "dumbbell.fill")
            ],
            displayName: nil,
            displayNameCopy: .consistentStudent,
            weekLabel: nil,
            weekLabelCopy: .currentWeek
        )
    }

    /// Retorna métricas de usuário expert com progresso máximo
    static func beastMode() -> ProgressMetrics {
        ProgressMetrics(
            weeklyCompletion: 1.0,
            streakDays: 14,
            badges: [
                Badge(id: "b1", systemImageName: "sparkles"),
                Badge(id: "b2", systemImageName: "dumbbell.fill"),
                Badge(id: "b3", systemImageName: "checkmark.seal.fill")
            ],
            displayName: nil,
            displayNameCopy: .beastMode,
            weekLabel: nil,
            weekLabelCopy: .currentWeek
        )
    }

    /// Retorna métricas aleatórias entre os cenários disponíveis
    static func random() -> ProgressMetrics {
        let options = [beginner(), consistent(), beastMode()]
        return options.randomElement() ?? beginner()
    }
}

import Foundation

/// Modelo de métricas de progresso consumido pela interface SpriteKit
struct ProgressMetrics: Hashable, Codable {

    /// Percentual de conclusão semanal normalizado entre 0 e 1
    var weeklyCompletion: Double

    /// Quantidade de dias consecutivos de atividade
    var streakDays: Int

    /// Lista de badges conquistadas pelo usuário
    var badges: [Badge]

    /// Nome de exibição opcional do usuário
    var displayName: String?

    /// Label opcional para identificar o período
    var weekLabel: String?

    /// Retorna instância vazia com valores padrão
    static var empty: ProgressMetrics {
        .init(
            weeklyCompletion: 0.0,
            streakDays: 0,
            badges: [],
            displayName: nil,
            weekLabel: nil
        )
    }
}

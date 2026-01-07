import Foundation

// MARK: - ProgressMetrics
// Modelo "agnóstico de UI" que a SpriteKit Scene consome.
struct ProgressMetrics: Hashable, Codable {

    // 0...1
    var weeklyCompletion: Double

    // Dias consecutivos (streak)
    var streakDays: Int

    // Badges desbloqueadas
    var badges: [Badge]

    // Exibição opcional (útil para professor)
    var displayName: String?

    // Label opcional (ex.: "Semana atual")
    var weekLabel: String?

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

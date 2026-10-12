import Foundation

enum ProgressGameCopy: String, Codable, Hashable {
    case generalProgress
    case currentWeek
    case previewStudent
    case consistentStudent
    case beastMode

    func localized(locale: Locale) -> String {
        switch self {
        case .generalProgress:
            return AppLocalization.string("gamification.week.general_progress", locale: locale)
        case .currentWeek:
            return AppLocalization.string("gamification.week.current", locale: locale)
        case .previewStudent:
            return AppLocalization.string("gamification.preview.student", locale: locale)
        case .consistentStudent:
            return AppLocalization.string(
                "gamification.preview.consistent_student",
                locale: locale
            )
        case .beastMode:
            return AppLocalization.string("gamification.preview.beast_mode", locale: locale)
        }
    }
}

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

    /// Texto de exibição fornecido pelo app para cenários de demonstração
    var displayNameCopy: ProgressGameCopy?

    /// Label opcional para identificar o período
    var weekLabel: String?

    /// Texto do período fornecido pelo app para cenários de demonstração
    var weekLabelCopy: ProgressGameCopy?

    /// Retorna instância vazia com valores padrão
    static var empty: ProgressMetrics {
        .init(
            weeklyCompletion: 0.0,
            streakDays: 0,
            badges: [],
            displayName: nil,
            displayNameCopy: nil,
            weekLabel: nil,
            weekLabelCopy: nil
        )
    }
}

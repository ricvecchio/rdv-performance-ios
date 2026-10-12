import Foundation

/// Representa uma conquista ou badge de gamificação com identificador, título e ícone
struct Badge: Identifiable, Hashable, Codable {
    /// Identificador único do badge
    let id: String
    /// Nome do ícone SF Symbol associado ao badge
    let systemImageName: String
    /// Título de conteúdo para badges não fornecidos pelo app
    let title: String?

    init(id: String, systemImageName: String, title: String? = nil) {
        self.id = id
        self.systemImageName = systemImageName
        self.title = title
    }

    func localizedTitle(locale: Locale) -> String {
        switch id {
        case "b1":
            return AppLocalization.string("gamification.badges.first_workout", locale: locale)
        case "b2":
            return AppLocalization.string("gamification.badges.three_workouts", locale: locale)
        case "b3":
            return AppLocalization.string("gamification.badges.consistency", locale: locale)
        case "b4":
            return AppLocalization.string("gamification.badges.complete_week", locale: locale)
        default:
            return title ?? id
        }
    }
}

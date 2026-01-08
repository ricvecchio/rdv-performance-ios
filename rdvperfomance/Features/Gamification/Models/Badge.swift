import Foundation

/// Representa uma conquista ou badge de gamificação com identificador, título e ícone
struct Badge: Identifiable, Hashable, Codable {
    /// Identificador único do badge
    let id: String
    /// Título descritivo do badge
    let title: String
    /// Nome do ícone SF Symbol associado ao badge
    let systemImageName: String
}

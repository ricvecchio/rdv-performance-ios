import Foundation

// MARK: - Badge (Gamificação)
// Representa uma conquista simples. Mantemos dados mínimos e estáveis.
struct Badge: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let systemImageName: String
}

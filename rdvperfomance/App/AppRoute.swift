import SwiftUI

// MARK: - Rotas do app
// Define todas as rotas possíveis da navegação via NavigationStack
enum AppRoute: Hashable {
    case login
    case home
    case sobre
    case treinos(TreinoTipo)

    // ✅ Novas rotas
    case perfil
    case configuracoes
}


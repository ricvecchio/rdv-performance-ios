import SwiftUI

// MARK: - APP CONTAINER / NAVIGATION
// View principal que contém o NavigationStack e controla a pilha de rotas (path).
struct AppRouter: View {

    // Estado responsável por armazenar a pilha de rotas do NavigationStack
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {

            // Rota inicial (primeira tela)
            LoginView(path: $path)

                // Mapeia cada rota para sua respectiva tela
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    case .login:
                        LoginView(path: $path)

                    case .home:
                        HomeView(path: $path)

                    case .sobre:
                        AboutView(path: $path)

                    case .treinos(let tipo):
                        TreinosView(path: $path, tipo: tipo)

                    // ✅ Novas telas
                    case .perfil:
                        ProfileView(path: $path)

                    case .configuracoes:
                        SettingsView(path: $path)

                    // ✅ NOVA tela do Crossfit (menu com 5 itens)
                    case .crossfitMenu:
                        CrossfitMenuView(path: $path)
                    }
                }
        }
    }
}


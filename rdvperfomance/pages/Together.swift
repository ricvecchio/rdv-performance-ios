import SwiftUI

// MARK: - APP CONTAINER / NAVIGATION
// View principal que contém o NavigationStack e controla a pilha de rotas (path).
// É aqui que centralizamos a navegação do app usando AppRoute.
struct Together: View {

    // Estado responsável por armazenar a pilha de rotas do NavigationStack
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {

            // Rota inicial (primeira tela)
            LoginPage(path: $path)

                // Mapeia cada rota para sua respectiva tela
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {

                    case .login:
                        LoginPage(path: $path)

                    case .home:
                        HomePage(path: $path)

                    case .sobre:
                        HomeLogoPage(path: $path)

                    case .treinos(let tipo):
                        TreinosPage(path: $path, tipo: tipo)
                    }
                }
        }
    }
}


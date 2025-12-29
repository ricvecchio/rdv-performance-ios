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

                    case .perfil:
                        ProfileView(path: $path)

                    case .configuracoes:
                        SettingsView(path: $path)

                    case .crossfitMenu:
                        CrossfitMenuView(path: $path)

                    // ✅ Fluxo Cadastro
                    case .accountTypeSelection:
                        AccountTypeSelectionView(path: $path)

                    case .registerStudent:
                        RegisterStudentView(path: $path)

                    case .registerTrainer:
                        RegisterTrainerView(path: $path)
                    }
                }
        }
    }
}


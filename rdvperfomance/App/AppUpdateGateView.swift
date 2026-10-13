import SwiftUI
import Combine

struct AppUpdateGateView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = AppUpdateViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .checking:
                splashView
            case .forceUpdate(let config):
                ForceUpdateView(config: config)
            case .upToDate, .optionalUpdate:
                // Mantém a abertura até a restauração inicial da sessão (evita exibir o login
                // momentaneamente quando já existe usuário autenticado)
                if session.isRestoringSession {
                    splashView
                } else {
                    AppRouter()
                }
            }
        }
        .task {
            await viewModel.checkForUpdate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            Task {
                await viewModel.revalidate()
            }
        }
    }

    // Mesma composição da LaunchScreen.storyboard (continuidade visual, sem tela branca):
    // imagem oficial proporcional e centralizada sobre o fundo escuro das bordas da imagem.
    private var splashView: some View {
        ZStack {
            Color(red: 0.063, green: 0.063, blue: 0.063)

            Image("rdv_splash")
                .resizable()
                .scaledToFit()
        }
        .ignoresSafeArea()
    }
}

@MainActor
private final class AppUpdateViewModel: ObservableObject {
    @Published private(set) var state: AppUpdateState = .checking

    private let service = AppVersionService()

    func checkForUpdate() async {
        state = .checking
        state = await service.updateState()
    }

    func revalidate() async {
        state = await service.updateState()
    }
}

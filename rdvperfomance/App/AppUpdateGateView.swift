import SwiftUI
import Combine

struct AppUpdateGateView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AppUpdateViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .checking:
                // Mesma composição da LaunchScreen.storyboard (continuidade visual, sem tela branca):
                // imagem oficial proporcional e centralizada sobre o fundo escuro das bordas da imagem.
                ZStack {
                    Color(red: 0.063, green: 0.063, blue: 0.063)

                    Image("rdv_splash")
                        .resizable()
                        .scaledToFit()
                }
                .ignoresSafeArea()
            case .forceUpdate(let config):
                ForceUpdateView(config: config)
            case .upToDate, .optionalUpdate:
                AppRouter()
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

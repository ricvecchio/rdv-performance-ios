import SwiftUI
import Combine

struct AppUpdateGateView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AppUpdateViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .checking:
                ProgressView()
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
                await viewModel.checkForUpdate()
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
}

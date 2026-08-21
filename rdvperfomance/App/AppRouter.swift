import SwiftUI

struct AppRouter: View {
    @State private var authenticationPath: [AppRoute] = []
    @StateObject private var session = AppSession()

    var body: some View {
        Group {
            if session.isLoggedIn {
                if session.isTrainer {
                    TeacherRootView()
                } else {
                    StudentRootView()
                }
            } else {
                NavigationStack(path: $authenticationPath) {
                    LoginView(path: $authenticationPath)
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .accountTypeSelection:
                                AccountTypeSelectionView(path: $authenticationPath)
                            case .registerStudent:
                                RegisterStudentView(path: $authenticationPath)
                            case .registerTrainer:
                                RegisterTrainerView(path: $authenticationPath)
                            default:
                                EmptyView()
                            }
                        }
                }
            }
        }
        .environmentObject(session)
        .onChange(of: session.isLoggedIn) { _, loggedIn in
            if !loggedIn {
                authenticationPath.removeAll()
            }
        }
    }
}

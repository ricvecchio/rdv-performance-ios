import SwiftUI
import FirebaseCore

@main
struct rdvperfomanceApp: App {

    // ✅ Inicializa Firebase no ciclo correto do iOS
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
        }
    }
}

// ✅ AppDelegate só para configurar Firebase
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}


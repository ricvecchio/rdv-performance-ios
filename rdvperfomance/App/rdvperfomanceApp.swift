import SwiftUI
import FirebaseCore
import CoreData

/// Ponto de entrada principal do aplicativo RDV Performance
@main
struct rdvperfomanceApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = AppSession()
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

/// Delegate para configurar Firebase no lançamento do app
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Configura Firebase quando o app é iniciado
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

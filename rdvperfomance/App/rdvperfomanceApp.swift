// rdvperfomanceApp.swift — Ponto de entrada do aplicativo e inicialização do Firebase
import SwiftUI
import FirebaseCore
import CoreData

@main
struct rdvperfomanceApp: App {

    // Inicializa AppDelegate para configurar Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Sessão global do app
    @StateObject private var session = AppSession()

    // Core Data Persistence
    private let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// AppDelegate usado apenas para configurar Firebase no lançamento
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

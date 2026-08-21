import SwiftUI
import FirebaseCore
import CoreData

// Ponto de entrada principal do aplicativo RDV Performance
@main
struct rdvperfomanceApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = AppSession()
    private let persistenceController = PersistenceController.shared

    // Define a janela principal do aplicativo com injeção de dependências
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// Configuração inicial do Firebase ao lançar o aplicativo
final class AppDelegate: NSObject, UIApplicationDelegate {
    // Inicializa o Firebase quando o app é iniciado
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}


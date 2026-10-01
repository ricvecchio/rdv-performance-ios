import SwiftUI
import FirebaseCore
import CoreData

// Ponto de entrada principal do aplicativo RDV Performance
@main
struct rdvperfomanceApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = AppSession()
    @AppStorage("selectedAppLanguage") private var selectedAppLanguage = AppLanguage.portugueseBrazil.rawValue
    private let persistenceController = PersistenceController.shared

    // Define a janela principal do aplicativo com injeção de dependências
    var body: some Scene {
        WindowGroup {
            AppUpdateGateView()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, Locale(identifier: selectedAppLanguage))
                .onAppear {
                    DashboardLocalizationDiagnostics.appLanguageChanged(selectedAppLanguage)
                }
                .onChange(of: selectedAppLanguage) { _, language in
                    DashboardLocalizationDiagnostics.appLanguageChanged(language)
                }
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

import SwiftUI
import FirebaseCore
import CoreData

// Ponto de entrada principal do aplicativo RDV Performance
@main
struct rdvperfomanceApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = AppSession()
    @AppStorage("selectedAppLanguage") private var selectedAppLanguage = AppLanguage.portugueseBrazil.rawValue
    @AppStorage(AppTheme.storageKey) private var selectedAppTheme = AppTheme.defaultTheme.rawValue
    private let persistenceController = PersistenceController.shared

    private var appTheme: AppTheme {
        AppTheme(storedValue: selectedAppTheme)
    }

    // Define a janela principal do aplicativo com injeção de dependências
    var body: some Scene {
        WindowGroup {
            AppUpdateGateView()
                .environmentObject(session)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environment(\.locale, Locale(identifier: selectedAppLanguage))
                .environment(\.appTheme, appTheme)
                .preferredColorScheme(appTheme.preferredColorScheme)
                .background(AppThemeWindowStyleApplier(theme: appTheme))
        }
    }
}

// Garante que a janela volte ao estilo original (não especificado) ao retornar ao Tema Escuro,
// já que `.preferredColorScheme(nil)` nem sempre restaura o estilo da janela imediatamente.
private struct AppThemeWindowStyleApplier: UIViewRepresentable {
    let theme: AppTheme

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let style: UIUserInterfaceStyle = theme == .light ? .light : .unspecified
        DispatchQueue.main.async {
            guard let window = uiView.window, window.overrideUserInterfaceStyle != style else { return }
            window.overrideUserInterfaceStyle = style
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

import SwiftUI
import UIKit
import Combine

/// Mantém o gesto nativo de swipe-back compatível com os botões `<` customizados do app.
///
/// A correção continua sendo reaplicada quando uma nova tela aparece, mas agora toda a stack usa
/// um único delegate compartilhado. Isso evita várias instâncias concorrendo pelo mesmo
/// `interactivePopGestureRecognizer.delegate` durante pushes, pops e updates de estado.
struct NavigationPopGestureFixer: UIViewControllerRepresentable {
    let installer: NavigationPopGestureInstaller

    func makeUIViewController(context: Context) -> ProbeViewController {
        ProbeViewController(installer: installer)
    }

    func updateUIViewController(_ uiViewController: ProbeViewController, context: Context) {
        uiViewController.installer = installer
        uiViewController.installIfPossible()
    }

    final class ProbeViewController: UIViewController {
        var installer: NavigationPopGestureInstaller

        init(installer: NavigationPopGestureInstaller) {
            self.installer = installer
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            installIfPossible()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installIfPossible()
        }

        func installIfPossible() {
            installer.install(on: navigationController)
        }
    }
}

@MainActor
final class NavigationPopGestureInstaller: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?

    func install(on navigationController: UINavigationController?) {
        guard let navigationController else { return }

        self.navigationController = navigationController

        guard let gesture = navigationController.interactivePopGestureRecognizer else { return }

        if gesture.delegate !== self {
            gesture.delegate = self
        }

        gesture.isEnabled = navigationController.viewControllers.count > 1
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

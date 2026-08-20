import SwiftUI
import UIKit

/// Mantém o gesto nativo de swipe-back compatível com os botões `<` customizados do app.
///
/// A instalação fica centralizada em um único host estável da stack para evitar reinstalações
/// concorrentes durante pushes/pops do `NavigationStack`.
struct NavigationPopGestureFixer: UIViewControllerRepresentable {
    let installer: NavigationPopGestureInstaller
    let stackDepth: Int

    func makeUIViewController(context: Context) -> ProbeViewController {
        ProbeViewController(installer: installer, stackDepth: stackDepth)
    }

    func updateUIViewController(_ uiViewController: ProbeViewController, context: Context) {
        uiViewController.installer = installer
        uiViewController.stackDepth = stackDepth
        uiViewController.installIfPossible(reason: "update")
    }

    final class ProbeViewController: UIViewController {
        var installer: NavigationPopGestureInstaller
        var stackDepth: Int

        init(installer: NavigationPopGestureInstaller, stackDepth: Int) {
            self.installer = installer
            self.stackDepth = stackDepth
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
            installIfPossible(reason: "didMove")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installIfPossible(reason: "viewDidAppear")
        }

        func installIfPossible(reason: StaticString) {
            installer.install(on: navigationController, stackDepth: stackDepth, reason: reason)
        }
    }
}

@MainActor
final class NavigationPopGestureInstaller: NSObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?
    private weak var installedGesture: UIGestureRecognizer?
    private var lastKnownStackDepth: Int = 0
    
    var isTransitioning: Bool {
        navigationController?.transitionCoordinator != nil
    }
    
    func canPush(
        route: AppRoute,
        onto path: [AppRoute],
        expectedTop: AppRoute? = nil,
        source: StaticString
    ) -> Bool {
        if isTransitioning {
            #if DEBUG
            log("push-blocked-transition route=\(String(describing: route))", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        if let expectedTop, path.last != expectedTop {
            #if DEBUG
            log("push-blocked-unexpected-top expected=\(String(describing: expectedTop)) actual=\(String(describing: path.last))", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        if path.last == route {
            #if DEBUG
            log("push-blocked-duplicate route=\(String(describing: route))", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        return true
    }
    
    func canPop(path: [AppRoute], expectedTop: AppRoute? = nil, source: StaticString) -> Bool {
        guard !path.isEmpty else {
            #if DEBUG
            log("pop-blocked-empty-path", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        if isTransitioning {
            #if DEBUG
            log("pop-blocked-transition", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        if let expectedTop, path.last != expectedTop {
            #if DEBUG
            log("pop-blocked-unexpected-top expected=\(String(describing: expectedTop)) actual=\(String(describing: path.last))", reason: source, stackDepth: path.count)
            #endif
            return false
        }
        
        return true
    }

    func install(on navigationController: UINavigationController?, stackDepth: Int, reason: StaticString) {
        guard let navigationController else { return }

        guard let gesture = navigationController.interactivePopGestureRecognizer else { return }

        let navigationControllerChanged = self.navigationController !== navigationController
        let gestureChanged = installedGesture !== gesture

        self.navigationController = navigationController
        self.installedGesture = gesture
        self.lastKnownStackDepth = stackDepth

        let transitioning = navigationController.transitionCoordinator != nil
        if transitioning {
            #if DEBUG
            log("install-skipped-transition", reason: reason, stackDepth: stackDepth)
            #endif
            return
        }

        if navigationControllerChanged || gestureChanged {
            #if DEBUG
            log("attach", reason: reason, stackDepth: stackDepth)
            #endif
        }

        if gesture.delegate !== self {
            #if DEBUG
            log("delegate-set", reason: reason, stackDepth: stackDepth)
            #endif
            gesture.delegate = self
        }

        let shouldEnable = stackDepth > 0 && navigationController.viewControllers.count > 1
        if gesture.isEnabled != shouldEnable {
            gesture.isEnabled = shouldEnable
            #if DEBUG
            log("enabled=\(shouldEnable)", reason: reason, stackDepth: stackDepth)
            #endif
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let controllerCount = navigationController?.viewControllers.count ?? 0
        let shouldBegin = !isTransitioning && lastKnownStackDepth > 0 && controllerCount > 1

        #if DEBUG
        log("shouldBegin=\(shouldBegin)", reason: "gesture", stackDepth: lastKnownStackDepth)
        #endif

        return shouldBegin
    }

    #if DEBUG
    private func log(_ event: String, reason: StaticString, stackDepth: Int) {
        let controllerCount = navigationController?.viewControllers.count ?? 0
        let transitioning = navigationController?.transitionCoordinator != nil
        print(
            "[NavPopGesture]",
            event,
            "reason=\(reason)",
            "stackDepth=\(stackDepth)",
            "viewControllers=\(controllerCount)",
            "transitioning=\(transitioning)"
        )
    }
    #endif
}

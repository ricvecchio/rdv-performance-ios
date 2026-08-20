import SwiftUI
import UIKit
import Combine

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
final class NavigationPopGestureInstaller: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    private weak var navigationController: UINavigationController?
    private weak var installedGesture: UIGestureRecognizer?
    private var lastKnownStackDepth: Int = 0

    /// Token da transição (push/pop programático ou swipe interativo) atualmente em andamento.
    /// Usado para evitar que uma conclusão "atrasada" de uma transição antiga limpe o estado
    /// de uma transição mais nova que já começou.
    private var activeTransitionToken: UUID?

    /// Coordinator já observado (evita registrar múltiplos completions para a mesma transição).
    private weak var observedCoordinator: UIViewControllerTransitionCoordinator?

    /// Reflete se existe uma transição REAL em andamento (push, pop ou swipe interativo).
    /// Alterado apenas por eventos reais do UIKit — nunca por timers ou delays artificiais.
    @Published private(set) var isTransitioning: Bool = false

    private func beginTransition(reason: StaticString) -> UUID {
        let token = UUID()
        activeTransitionToken = token
        if !isTransitioning {
            isTransitioning = true
            #if DEBUG
            log("transition-START", reason: reason, stackDepth: lastKnownStackDepth)
            #endif
        }
        return token
    }

    private func endTransition(token: UUID, reason: StaticString) {
        // Só encerra se este token ainda for o da transição ativa (evita corrida entre
        // a conclusão de uma transição antiga e o início de uma nova).
        guard activeTransitionToken == token else { return }
        activeTransitionToken = nil
        observedCoordinator = nil
        isTransitioning = false
        #if DEBUG
        log("transition-END", reason: reason, stackDepth: lastKnownStackDepth)
        #endif
    }

    /// Observa o `transitionCoordinator` real de um push/pop programático e libera o estado
    /// de transição exatamente quando a animação termina (cancelada ou concluída).
    private func observeCoordinatorIfNeeded(_ coordinator: UIViewControllerTransitionCoordinator, reason: StaticString) {
        guard observedCoordinator !== coordinator else { return }
        observedCoordinator = coordinator
        let token = beginTransition(reason: reason)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.endTransition(token: token, reason: "coordinator-completion")
            }
        }
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

    /// Ponto único de push: garante que "um evento de usuário = uma operação de navegação".
    @discardableResult
    func pushIfPossible(
        route: AppRoute,
        path: inout [AppRoute],
        expectedTop: AppRoute? = nil,
        source: StaticString
    ) -> Bool {
        guard canPush(route: route, onto: path, expectedTop: expectedTop, source: source) else { return false }

        // Marca a transição como iniciada imediatamente (mesmo turno de execução do tap),
        // para que o botão seja desabilitado antes que um segundo toque possa chegar.
        // O estado real é confirmado/encerrado depois via transitionCoordinator.
        _ = beginTransition(reason: source)
        path.append(route)
        return true
    }

    /// Ponto único de pop: garante que "um evento de usuário = uma operação de navegação".
    @discardableResult
    func popIfPossible(
        path: inout [AppRoute],
        expectedTop: AppRoute? = nil,
        source: StaticString
    ) -> Bool {
        guard canPop(path: path, expectedTop: expectedTop, source: source) else { return false }

        _ = beginTransition(reason: source)
        path.removeLast()
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

        if let coordinator = navigationController.transitionCoordinator {
            // Existe uma transição real em andamento (push/pop/swipe). Anexa o observador
            // de conclusão para liberar `isTransitioning` no momento exato em que ela termina.
            observeCoordinatorIfNeeded(coordinator, reason: reason)
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

        if !hasObservedGesture(gesture) {
            // addTarget não substitui os targets internos do UIKit; apenas nos permite
            // observar o ciclo de vida real do gesto interativo (swipe-back).
            gesture.addTarget(self, action: #selector(handleInteractivePopGesture(_:)))
            markGestureObserved(gesture)
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

    private var interactiveGestureToken: UUID?
    private weak var gestureWithObservedTarget: UIGestureRecognizer?

    private func hasObservedGesture(_ gesture: UIGestureRecognizer) -> Bool {
        gestureWithObservedTarget === gesture
    }

    private func markGestureObserved(_ gesture: UIGestureRecognizer) {
        gestureWithObservedTarget = gesture
    }

    /// Acompanha o ciclo de vida real do swipe-back (`.began` → `.ended`/`.cancelled`/`.failed`)
    /// para manter `isTransitioning` sincronizado também durante o gesto interativo,
    /// sem depender de timers.
    @objc private func handleInteractivePopGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            interactiveGestureToken = beginTransition(reason: "swipe-began")

        case .ended, .cancelled, .failed:
            if let token = interactiveGestureToken {
                endTransition(token: token, reason: "swipe-ended")
            }
            interactiveGestureToken = nil

        default:
            break
        }
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

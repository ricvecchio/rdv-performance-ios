import SwiftUI
import QuartzCore
import UIKit

#if DEBUG
struct NavigationDebugButtonStyle: ButtonStyle {
    let name: String
    let probe: NavigationHeaderDebugProbe?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                print("[NAV][TOUCH][\(name)]", CACurrentMediaTime(), "isPressed:", pressed)
                probe?.recordButtonPressed(pressed)
            }
    }
}

final class NavigationHeaderDebugProbe: ObservableObject {
    private struct TouchSnapshot {
        let point: CGPoint
        let window: UIWindow?
        var didReachButton = false
        var ended = false
    }

    let name: String
    private var frame: CGRect = .zero
    private var pendingTouch: TouchSnapshot?

    init(name: String) {
        self.name = name
    }

    func recordFrame(_ frame: CGRect) {
        guard self.frame != frame else { return }
        self.frame = frame
        print(
            "[NAV][FRAME][\(name)]",
            CACurrentMediaTime(),
            "x:", frame.origin.x,
            "y:", frame.origin.y,
            "w:", frame.size.width,
            "h:", frame.size.height
        )
    }

    func recordTouchDown(at point: CGPoint, in window: UIWindow?) {
        guard frame.contains(point) else { return }

        if let pendingTouch, pendingTouch.ended {
            logMissingAction(for: pendingTouch)
        }

        pendingTouch = TouchSnapshot(point: point, window: window)
        print("[NAV][HIT][\(name)] DOWN", CACurrentMediaTime())
        logNavigationBarState(in: window)
    }

    func recordTouchUp(at point: CGPoint, in window: UIWindow?) {
        guard frame.contains(point), pendingTouch != nil else { return }
        pendingTouch?.ended = true
        print("[NAV][HIT][\(name)] UP", CACurrentMediaTime())
        logNavigationBarState(in: window)
    }

    func recordButtonPressed(_ pressed: Bool) {
        guard pressed else { return }
        pendingTouch?.didReachButton = true
    }

    func recordAction() {
        pendingTouch = nil
    }

    private func logMissingAction(for touch: TouchSnapshot) {
        let result = touch.didReachButton ? "C" : "B"
        print("[NAV][RESULT][\(name)] \(result) action ausente no toque anterior", CACurrentMediaTime())
        logHitTest(at: touch.point, in: touch.window)
        pendingTouch = nil
    }

    private func logNavigationBarState(in window: UIWindow?) {
        guard let navigationController = navigationController(in: window) else {
            print("[NAV][BAR] navigationController: nil")
            return
        }

        let bar = navigationController.navigationBar
        let barFrame = bar.convert(bar.bounds, to: window)
        print(
            "[NAV][BAR]",
            "navigationController:", String(describing: type(of: navigationController)),
            "frame:", barFrame,
            "viewControllers:", navigationController.viewControllers.count,
            "transitionCoordinatorActive:", navigationController.transitionCoordinator != nil,
            "userInteractionEnabled:", bar.isUserInteractionEnabled,
            "alpha:", bar.alpha,
            "isHidden:", bar.isHidden
        )
    }

    private func logHitTest(at point: CGPoint, in window: UIWindow?) {
        guard let window else {
            print("[NAV][HIERARCHY][\(name)] window: nil")
            return
        }

        let hitView = window.hitTest(point, with: nil)
        let chain = superviewChain(from: hitView)
        let containsTransitionView = chain.contains { $0.contains("UITransitionView") }
        let overlays = overlaysAboveNavigationBar(in: navigationController(in: window))
        print(
            "[NAV][HIERARCHY][\(name)]",
            "hit:", hitView.map { String(describing: type(of: $0)) } ?? "nil",
            "chain:", chain.joined(separator: " -> "),
            "containsUITransitionView:", containsTransitionView,
            "overlaysAboveNavigationBar:", overlays
        )
    }

    private func navigationController(in window: UIWindow?) -> UINavigationController? {
        guard let rootViewController = window?.rootViewController else { return nil }
        return findNavigationController(in: rootViewController)
    }

    private func findNavigationController(in viewController: UIViewController) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        if let presentedViewController = viewController.presentedViewController,
           let navigationController = findNavigationController(in: presentedViewController) {
            return navigationController
        }

        for child in viewController.children.reversed() {
            if let navigationController = findNavigationController(in: child) {
                return navigationController
            }
        }

        return nil
    }

    private func superviewChain(from view: UIView?) -> [String] {
        var chain: [String] = []
        var currentView = view

        while let view = currentView, chain.count < 8 {
            chain.append(String(describing: type(of: view)))
            currentView = view.superview
        }

        return chain
    }

    private func overlaysAboveNavigationBar(in navigationController: UINavigationController?) -> [String] {
        guard let navigationController else { return [] }

        let navigationBar = navigationController.navigationBar
        guard let navigationBarIndex = navigationController.view.subviews.firstIndex(where: { $0 === navigationBar }) else {
            return []
        }

        return navigationController.view.subviews
            .dropFirst(navigationBarIndex + 1)
            .filter {
                !$0.isHidden &&
                $0.alpha > 0.01 &&
                $0.frame.intersects(navigationBar.frame)
            }
            .prefix(4)
            .map { String(describing: type(of: $0)) }
    }
}

struct NavigationHeaderProbeAttachment: View {
    @ObservedObject var probe: NavigationHeaderDebugProbe

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .background(NavigationPassiveTouchProbe(probe: probe))
                .onAppear {
                    probe.recordFrame(geometry.frame(in: .global))
                }
                .onChange(of: geometry.frame(in: .global)) { _, frame in
                    probe.recordFrame(frame)
                }
        }
    }
}

struct NavigationPassiveTouchProbe: UIViewRepresentable {
    let probe: NavigationHeaderDebugProbe

    func makeUIView(context: Context) -> PassiveTouchProbeView {
        PassiveTouchProbeView(probe: probe)
    }

    func updateUIView(_ uiView: PassiveTouchProbeView, context: Context) {
        uiView.probe = probe
    }
}

final class PassiveTouchProbeView: UIView {
    weak var probe: NavigationHeaderDebugProbe?
    private weak var observedSuperview: UIView?
    private lazy var touchRecognizer = PassiveTouchRecognizer { [weak self] phase, point, window in
        switch phase {
        case .down:
            self?.probe?.recordTouchDown(at: point, in: window)
        case .up:
            self?.probe?.recordTouchUp(at: point, in: window)
        }
    }

    init(probe: NavigationHeaderDebugProbe) {
        self.probe = probe
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard observedSuperview !== superview else { return }
        observedSuperview?.removeGestureRecognizer(touchRecognizer)
        observedSuperview = superview
        observedSuperview?.addGestureRecognizer(touchRecognizer)
    }

    deinit {
        observedSuperview?.removeGestureRecognizer(touchRecognizer)
    }
}

final class PassiveTouchRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {
    enum Phase {
        case down
        case up
    }

    private let handler: (Phase, CGPoint, UIWindow?) -> Void

    init(handler: @escaping (Phase, CGPoint, UIWindow?) -> Void) {
        self.handler = handler
        super.init(target: nil, action: nil)
        delegate = self
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        handler(.down, touch.location(in: touch.window), touch.window)
        state = .began
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else {
            state = .failed
            return
        }
        handler(.up, touch.location(in: touch.window), touch.window)
        state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }

    override func canPrevent(_ preventedGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

#endif

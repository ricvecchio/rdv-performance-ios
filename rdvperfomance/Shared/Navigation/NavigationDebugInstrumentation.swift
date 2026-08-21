import SwiftUI
import UIKit
import QuartzCore

#if DEBUG
struct NavigationDebugButtonStyle: ButtonStyle {
    let name: String

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                print("[NAV][TOUCH][\(name)]", CACurrentMediaTime(), "isPressed:", pressed)
            }
    }
}

struct NavigationTransitionDebugProbe: UIViewControllerRepresentable {
    let name: String

    func makeUIViewController(context: Context) -> ProbeViewController {
        ProbeViewController(name: name)
    }

    func updateUIViewController(_ viewController: ProbeViewController, context: Context) {
        viewController.name = name
        viewController.logTransitionState(event: "update")
    }

    final class ProbeViewController: UIViewController {
        var name: String

        init(name: String) {
            self.name = name
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            logTransitionState(event: "didMove")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            logTransitionState(event: "viewDidAppear")
        }

        func logTransitionState(event: String) {
            let transitionActive = navigationController?.transitionCoordinator != nil
            print(
                "[NAV][TRANSITION][\(name)]",
                CACurrentMediaTime(),
                event,
                "transitionCoordinator:",
                transitionActive
            )
        }
    }
}
#endif

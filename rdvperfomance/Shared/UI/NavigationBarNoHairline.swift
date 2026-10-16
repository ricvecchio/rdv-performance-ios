import SwiftUI
import UIKit

struct NavigationBarNoHairline: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = NavBarNoHairlineController()
        controller.theme = context.environment.appTheme
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let controller = uiViewController as? NavBarNoHairlineController else { return }
        let theme = context.environment.appTheme
        guard controller.theme != theme else { return }
        controller.theme = theme
        controller.applyIfVisible()
    }

    private final class NavBarNoHairlineController: UIViewController {

        var theme: AppTheme = .dark

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        func applyIfVisible() {
            guard viewIfLoaded?.window != nil else { return }
            apply()
        }

        private func apply() {
            guard let nav = navigationController else { return }
            let bar = nav.navigationBar

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.Colors.headerBackgroundColor(for: theme))
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            appearance.backgroundEffect = nil

            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance

            bar.layer.shadowOpacity = 0
            bar.layer.shadowRadius = 0
            bar.layer.shadowOffset = .zero
            bar.layer.shadowColor = UIColor.clear.cgColor
        }
    }
}

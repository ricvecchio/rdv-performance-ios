import SwiftUI
import UIKit

struct NavigationBarNoHairline: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UIViewController {
        NavBarNoHairlineController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    private final class NavBarNoHairlineController: UIViewController {

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        private func apply() {
            guard let nav = navigationController else { return }
            let bar = nav.navigationBar

            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Theme.Colors.headerBackground)
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

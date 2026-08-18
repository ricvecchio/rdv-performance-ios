import SwiftUI
import UIKit

/// Corrige uma race conhecida entre o gesto de "voltar por swipe" do `UINavigationController`
/// (`interactivePopGestureRecognizer`) e os botões de voltar customizados usados em todas as
/// telas do app (`.navigationBarBackButtonHidden(true)` + `Button { pop() }` no toolbar).
///
/// CAUSA RAIZ do "preciso tocar duas vezes na seta `<`": mesmo com o back button do sistema
/// oculto, o `interactivePopGestureRecognizer` continua instalado e ativo. Por padrão, o
/// `UINavigationController` é seu próprio delegate e exige que outros gestos (como o
/// `UITapGestureRecognizer` interno do `Button` customizado, posicionado bem próximo à borda
/// esquerda da navigation bar) "falhem" antes de reconhecer o toque. Isso faz o botão mostrar
/// o estado pressionado (feedback visual) no primeiro toque, mas só disparar a ação no
/// segundo, porque a resolução do gesto concorrente atrasa o reconhecimento do tap.
///
/// A correção reatribui o delegate do `interactivePopGestureRecognizer` para um delegate
/// neutro que permite reconhecimento simultâneo, preservando o swipe-to-back (não removemos
/// a funcionalidade), mas eliminando a exigência de falha mútua que causava o toque duplo.
/// Aplicado uma única vez, no `NavigationStack` raiz (`AppRouter`), em vez de espalhado por
/// cada tela.
struct NavigationPopGestureFixer: UIViewControllerRepresentable {

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // O navigationController só fica disponível depois que a hierarquia é montada.
        DispatchQueue.main.async {
            guard let nav = uiViewController.navigationController else { return }
            context.coordinator.navigationController = nav
            if nav.interactivePopGestureRecognizer?.delegate !== context.coordinator {
                nav.interactivePopGestureRecognizer?.delegate = context.coordinator
            }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        // Mantém o comportamento padrão de não iniciar o swipe-back quando não há
        // para onde voltar (root da stack), evitando animações "fantasma".
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }

        // Permite que o gesto de swipe-back e o tap do botão customizado sejam
        // reconhecidos simultaneamente, removendo a exigência de "falha mútua" que
        // causava a necessidade de dois toques no botão de voltar.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

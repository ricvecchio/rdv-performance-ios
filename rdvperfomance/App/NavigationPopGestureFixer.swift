import SwiftUI
import UIKit

/// Corrige uma race conhecida entre o gesto de "voltar por swipe" do `UINavigationController`
/// (`interactivePopGestureRecognizer`) e os botões de voltar customizados usados em todas as
/// telas do app (`.navigationBarBackButtonHidden(true)` + `Button { pop() }` no toolbar).
///
/// CAUSA RAIZ do "preciso tocar duas vezes na seta `<`": mesmo com o back button do sistema
/// oculto, o `interactivePopGestureRecognizer` continua instalado e ativo, e ele é um
/// `UIScreenEdgePanGestureRecognizer` que monitora justamente a faixa esquerda da tela — a
/// mesma região onde o botão `<` customizado fica posicionado na navigation bar. Por padrão o
/// `UINavigationController` é seu próprio delegate e exige que outros gestos (como o
/// `UITapGestureRecognizer` interno do `Button` customizado) "falhem" antes de reconhecer o
/// toque. Isso faz o botão mostrar o estado pressionado (feedback visual) no primeiro toque,
/// mas só disparar a ação no segundo, porque a resolução do gesto concorrente atrasa/perde o
/// reconhecimento do tap.
///
/// IMPORTANTE: reatribuir `interactivePopGestureRecognizer.delegate` UMA ÚNICA VEZ, apenas na
/// montagem da view raiz do `NavigationStack`, não é suficiente. É um comportamento conhecido do
/// `UINavigationController` "esquecer"/resetar esse delegate para um estado neutro em torno de
/// transições de push/pop subsequentes (o mesmo motivo pelo qual, historicamente em UIKit puro,
/// a recomendação é reatribuir esse delegate em `viewWillAppear`/`viewDidAppear` de cada tela, e
/// não apenas uma vez em `viewDidLoad`). Isso explica por que o bug parecia "intermitente" e
/// aparecia em qualquer tela com botão `<` — inclusive em telas cujo `pop()` já fazia
/// `removeLast()` corretamente (ex.: `SettingsView`): a causa não estava na lógica do `path`, e
/// sim no gesto de swipe voltando a exigir falha mútua depois de cada navegação, silenciosamente
/// desfazendo a correção aplicada apenas na raiz.
///
/// Por isso este `UIViewControllerRepresentable` é aplicado não só na tela raiz, mas em
/// `.background(NavigationPopGestureFixer())` de CADA destino de navegação (veja
/// `AppRouter.navigationDestination`). Cada nova tela empurrada reaplica o delegate neutro no
/// momento em que aparece, garantindo que a correção permaneça válida em qualquer profundidade
/// da pilha, sem depender de uma única aplicação no início. Não sobrescrevemos
/// `UINavigationController.delegate` (arriscaria quebrar a sincronização interna do SwiftUI
/// entre o gesto de swipe-back e o `path` do `NavigationStack`) — mexemos apenas no delegate do
/// `interactivePopGestureRecognizer`, de forma idempotente.
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

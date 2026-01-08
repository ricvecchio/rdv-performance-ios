import SpriteKit
import Foundation

/// Factory para criação de cenas ProgressGameScene configuradas
enum ProgressGameSceneFactory {

    /// Cria e configura uma nova cena ProgressGameScene com tamanho especificado
    static func makeScene(size: CGSize) -> ProgressGameScene {
        let scene = ProgressGameScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}

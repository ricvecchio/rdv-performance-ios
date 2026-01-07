import SpriteKit
import Foundation

enum ProgressGameSceneFactory {

    static func makeScene(size: CGSize) -> ProgressGameScene {
        let scene = ProgressGameScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }
}

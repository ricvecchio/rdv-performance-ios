import SpriteKit

// Cena simples de demonstração do SpriteKit
class GameScene: SKScene {
    private static var localizationLocale: Locale {
        Locale(
            identifier: UserDefaults.standard.string(forKey: "selectedAppLanguage")
                ?? AppLanguage.portugueseBrazil.rawValue
        )
    }

    // Configura a cena quando é apresentada na view
    override func didMove(to view: SKView) {
        backgroundColor = .white

        let label = SKLabelNode(
            text: String(localized: "sprites.greeting", locale: Self.localizationLocale)
        )
        label.fontSize = 28
        label.fontColor = .black
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)

        let sprite = SKShapeNode(circleOfRadius: 24)
        sprite.fillColor = .systemGreen
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        addChild(sprite)

        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.8)
        let moveDown = moveUp.reversed()
        let seq = SKAction.sequence([moveUp, moveDown])
        sprite.run(.repeatForever(seq))
    }

    // Altera cor de fundo ao tocar na tela
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = self.backgroundColor == .white ? .lightGray : .white
    }
}

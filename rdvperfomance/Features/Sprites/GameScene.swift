import SpriteKit

class GameScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = .white

        let label = SKLabelNode(text: "Olá SpriteKit")
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Example interaction: change background color on touch
        self.backgroundColor = self.backgroundColor == .white ? .lightGray : .white
    }
}

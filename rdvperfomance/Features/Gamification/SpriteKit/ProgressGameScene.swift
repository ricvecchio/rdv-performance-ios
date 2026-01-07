import SpriteKit
import Foundation

// MARK: - ProgressGameScene
// Cena simples: anel de progresso + streak + badges.
// Sem dependência de Theme (SpriteKit não lê Theme facilmente), então mantemos visual neutro.
final class ProgressGameScene: SKScene {

    private let ringBackground = SKShapeNode()
    private let ringProgress = SKShapeNode()

    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let streakLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    private let badgesContainer = SKNode()

    private var currentMetrics: ProgressMetrics = .empty

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupIfNeeded()
        apply(metrics: currentMetrics, animated: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutNodes()
        apply(metrics: currentMetrics, animated: false)
    }

    func update(with metrics: ProgressMetrics, animated: Bool = true) {
        currentMetrics = metrics
        apply(metrics: metrics, animated: animated)
    }

    // MARK: - Setup
    private func setupIfNeeded() {
        guard ringBackground.parent == nil else { return }

        addChild(ringBackground)
        addChild(ringProgress)

        addChild(titleLabel)
        addChild(subtitleLabel)
        addChild(streakLabel)
        addChild(badgesContainer)

        // Labels
        titleLabel.fontSize = 18
        titleLabel.fontColor = .white
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center

        subtitleLabel.fontSize = 12
        subtitleLabel.fontColor = UIColor.white.withAlphaComponent(0.65)
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center

        streakLabel.fontSize = 16
        streakLabel.fontColor = .white
        streakLabel.horizontalAlignmentMode = .center
        streakLabel.verticalAlignmentMode = .center

        // Ring base style
        ringBackground.strokeColor = UIColor.white.withAlphaComponent(0.20)
        ringBackground.fillColor = .clear
        ringBackground.lineWidth = 12
        ringBackground.lineCap = .round

        ringProgress.strokeColor = UIColor.systemGreen.withAlphaComponent(0.90)
        ringProgress.fillColor = .clear
        ringProgress.lineWidth = 12
        ringProgress.lineCap = .round

        layoutNodes()
    }

    private func layoutNodes() {
        let center = CGPoint(x: size.width / 2.0, y: size.height * 0.60)

        // Ring radius adaptativo
        let radius = min(size.width, size.height) * 0.18

        let circlePath = UIBezierPath(
            arcCenter: .zero,
            radius: radius,
            startAngle: CGFloat(-Double.pi / 2),
            endAngle: CGFloat(3 * Double.pi / 2),
            clockwise: true
        )

        ringBackground.path = circlePath.cgPath
        ringProgress.path = circlePath.cgPath

        ringBackground.position = center
        ringProgress.position = center

        titleLabel.position = CGPoint(x: center.x, y: center.y + radius + 34)
        subtitleLabel.position = CGPoint(x: center.x, y: center.y + radius + 16)
        streakLabel.position = CGPoint(x: center.x, y: center.y - radius - 26)

        badgesContainer.position = CGPoint(x: size.width / 2.0, y: size.height * 0.22)
    }

    // MARK: - Apply metrics
    private func apply(metrics: ProgressMetrics, animated: Bool) {

        // Textos
        let name = (metrics.displayName?.isEmpty == false) ? metrics.displayName! : "Progresso"
        titleLabel.text = name
        subtitleLabel.text = metrics.weekLabel ?? "Semana"

        let percent = Int((max(0.0, min(1.0, metrics.weeklyCompletion)) * 100.0).rounded())
        streakLabel.text = "🔥 Streak: \(metrics.streakDays) dias • \(percent)%"

        // Ring
        let clamped = max(0.0, min(1.0, metrics.weeklyCompletion))
        let targetStrokeEnd = CGFloat(clamped)

        // Em SKShapeNode não existe "strokeEnd" nativo como CAShapeLayer.
        // Solução simples e confiável: desenhar arco do progresso.
        let radius = min(size.width, size.height) * 0.18
        let endAngle = CGFloat(-Double.pi / 2) + (CGFloat(2 * Double.pi) * targetStrokeEnd)

        let progressPath = UIBezierPath(
            arcCenter: .zero,
            radius: radius,
            startAngle: CGFloat(-Double.pi / 2),
            endAngle: endAngle,
            clockwise: true
        )
        ringProgress.path = progressPath.cgPath

        // Badges
        rebuildBadges(metrics.badges, animated: animated)
    }

    private func rebuildBadges(_ badges: [Badge], animated: Bool) {
        badgesContainer.removeAllChildren()

        guard !badges.isEmpty else {
            let empty = SKLabelNode(fontNamed: "AvenirNext-Regular")
            empty.text = "Sem badges ainda — continue treinando!"
            empty.fontSize = 12
            empty.fontColor = UIColor.white.withAlphaComponent(0.55)
            empty.horizontalAlignmentMode = .center
            empty.verticalAlignmentMode = .center
            badgesContainer.addChild(empty)
            return
        }

        // Layout horizontal simples
        let spacing: CGFloat = 12
        let maxCount = min(badges.count, 4)
        let shown = Array(badges.prefix(maxCount))

        let itemWidth: CGFloat = 110
        let totalWidth = (CGFloat(shown.count) * itemWidth) + (CGFloat(shown.count - 1) * spacing)
        var x = -totalWidth / 2

        for b in shown {
            let node = badgeNode(title: b.title, systemImageName: b.systemImageName)
            node.position = CGPoint(x: x + itemWidth / 2, y: 0)
            badgesContainer.addChild(node)

            if animated {
                node.setScale(0.01)
                node.run(.sequence([
                    .wait(forDuration: 0.05),
                    .scale(to: 1.0, duration: 0.22)
                ]))
            }
            x += itemWidth + spacing
        }
    }

    private func badgeNode(title: String, systemImageName: String) -> SKNode {
        let container = SKNode()

        // Fundo
        let bg = SKShapeNode(rectOf: CGSize(width: 118, height: 44), cornerRadius: 10)
        bg.fillColor = UIColor.black.withAlphaComponent(0.35)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.10)
        bg.lineWidth = 1
        container.addChild(bg)

        // Ícone (fallback: apenas texto se não renderizar SF Symbol no SpriteKit)
        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.text = "★"
        icon.fontSize = 14
        icon.fontColor = UIColor.systemGreen.withAlphaComponent(0.90)
        icon.position = CGPoint(x: -42, y: -6)
        container.addChild(icon)

        // Título
        let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = title
        label.fontSize = 10
        label.fontColor = UIColor.white.withAlphaComponent(0.90)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -28, y: 0)
        container.addChild(label)

        return container
    }
}

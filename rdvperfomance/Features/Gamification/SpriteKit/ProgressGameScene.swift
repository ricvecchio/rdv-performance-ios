import SpriteKit
import Foundation

/// Cena SpriteKit que exibe progresso gamificado com anel, streak e badges
final class ProgressGameScene: SKScene {

    /// Anel de fundo que representa o progresso total possível
    private let ringBackground = SKShapeNode()
    /// Anel colorido que representa o progresso atual
    private let ringProgress = SKShapeNode()

    /// Label principal com nome do usuário
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    /// Label secundária com período de referência
    private let subtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    /// Label que exibe streak e percentual
    private let streakLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    /// Container para organizar badges
    private let badgesContainer = SKNode()

    /// Métricas atualmente exibidas na cena
    private var currentMetrics: ProgressMetrics = .empty
    private var currentLocale = Locale.current
    private var usesPreviewBadgeLayout = false

    /// Configura elementos da cena quando adicionada à view
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupIfNeeded()
        apply(metrics: currentMetrics, animated: false)
    }

    /// Recalcula layout quando tamanho da cena muda
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutNodes()
        apply(metrics: currentMetrics, animated: false)
    }

    /// Atualiza métricas exibidas na cena com opção de animação
    func update(with metrics: ProgressMetrics, locale: Locale = .current, animated: Bool = true) {
        currentMetrics = metrics
        currentLocale = locale
        apply(metrics: metrics, animated: animated)
    }

    func configurePreviewBadgeLayout() {
        usesPreviewBadgeLayout = true
    }

    /// Configura nós da cena uma única vez evitando duplicação
    private func setupIfNeeded() {
        guard ringBackground.parent == nil else { return }

        addChild(ringBackground)
        addChild(ringProgress)

        addChild(titleLabel)
        addChild(subtitleLabel)
        addChild(streakLabel)
        addChild(badgesContainer)

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

    /// Posiciona todos os elementos na cena baseado no tamanho disponível
    private func layoutNodes() {
        let center = CGPoint(
            x: size.width / 2.0,
            y: size.height * (usesPreviewBadgeLayout ? 0.68 : 0.60)
        )

        /// Calcula raio adaptativo baseado no menor lado da tela
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

        badgesContainer.position = CGPoint(
            x: size.width / 2.0,
            y: size.height * (usesPreviewBadgeLayout ? 0.25 : 0.22)
        )
    }

    /// Aplica métricas fornecidas aos elementos visuais da cena
    private func apply(metrics: ProgressMetrics, animated: Bool) {

        /// Define textos dos labels com dados das métricas
        let name = (metrics.displayName?.isEmpty == false) ? metrics.displayName! : "Progresso"
        titleLabel.text = localized(name)
        subtitleLabel.text = localized(metrics.weekLabel ?? "Semana")

        let percent = Int((max(0.0, min(1.0, metrics.weeklyCompletion)) * 100.0).rounded())
        let format = localized("🔥 Streak: %lld %@ • %lld%%")
        streakLabel.text = String(
            format: format,
            locale: currentLocale,
            arguments: [Int64(metrics.streakDays), localized("dias"), Int64(percent)]
        )

        /// Desenha arco de progresso baseado no percentual de conclusão
        let clamped = max(0.0, min(1.0, metrics.weeklyCompletion))
        let targetStrokeEnd = CGFloat(clamped)

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

        rebuildBadges(metrics.badges, animated: animated)
    }

    /// Reconstrói container de badges com animação opcional
    private func rebuildBadges(_ badges: [Badge], animated: Bool) {
        badgesContainer.removeAllChildren()

        let displayedBadges = usesPreviewBadgeLayout
            ? ProgressMetricsMock.beastMode().badges
            : badges

        /// Exibe mensagem quando não há badges conquistadas
        guard !displayedBadges.isEmpty else {
            let empty = SKLabelNode(fontNamed: "AvenirNext-Regular")
            empty.text = localized("Sem badges ainda — continue treinando!")
            empty.fontSize = 12
            empty.fontColor = UIColor.white.withAlphaComponent(0.55)
            empty.horizontalAlignmentMode = .center
            empty.verticalAlignmentMode = .center
            badgesContainer.addChild(empty)
            return
        }

        /// Limita a exibição a até 4 badges
        let spacing: CGFloat = 12
        let maxCount = min(displayedBadges.count, 4)
        let shown = Array(displayedBadges.prefix(maxCount))

        if usesPreviewBadgeLayout {
            let itemHeight: CGFloat = 48
            let spacing: CGFloat = 8
            let itemWidth = min(max(size.width - 40, 180), 320)
            let totalHeight = (CGFloat(shown.count) * itemHeight)
                + (CGFloat(shown.count - 1) * spacing)
            var y = (totalHeight - itemHeight) / 2.0

            for badge in shown {
                let node = previewBadgeNode(title: localized(badge.title), width: itemWidth)
                node.position = CGPoint(x: 0, y: y)
                badgesContainer.addChild(node)

                if animated {
                    node.setScale(0.01)
                    node.run(.sequence([
                        .wait(forDuration: 0.05),
                        .scale(to: 1.0, duration: 0.22)
                    ]))
                }
                y -= itemHeight + spacing
            }
            return
        }

        let itemWidth: CGFloat = 110
        let totalWidth = (CGFloat(shown.count) * itemWidth) + (CGFloat(shown.count - 1) * spacing)
        var x = -totalWidth / 2

        for b in shown {
            let node = badgeNode(title: localized(b.title), systemImageName: b.systemImageName)
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

    /// Cria nó visual para exibição de um badge individual
    private func badgeNode(title: String, systemImageName: String) -> SKNode {
        let container = SKNode()

        let bg = SKShapeNode(rectOf: CGSize(width: 118, height: 44), cornerRadius: 10)
        bg.fillColor = UIColor.black.withAlphaComponent(0.35)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.10)
        bg.lineWidth = 1
        container.addChild(bg)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.text = "★"
        icon.fontSize = 14
        icon.fontColor = UIColor.systemGreen.withAlphaComponent(0.90)
        icon.position = CGPoint(x: -42, y: -6)
        container.addChild(icon)

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

    private func localized(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), locale: currentLocale)
    }

    private func previewBadgeNode(title: String, width: CGFloat) -> SKNode {
        let container = SKNode()

        let background = SKShapeNode(
            rectOf: CGSize(width: width, height: 48),
            cornerRadius: 12
        )
        background.fillColor = UIColor.black.withAlphaComponent(0.65)
        background.strokeColor = UIColor.white.withAlphaComponent(0.08)
        background.lineWidth = 1
        container.addChild(background)

        let icon = SKLabelNode(fontNamed: "AvenirNext-Bold")
        icon.text = "★"
        icon.fontSize = 14
        icon.fontColor = UIColor.systemGreen.withAlphaComponent(0.90)
        icon.position = CGPoint(x: -(width / 2) + 22, y: -6)
        container.addChild(icon)

        let label = SKLabelNode(fontNamed: "AvenirNext-Regular")
        label.text = title
        label.fontSize = 14
        label.fontColor = UIColor.white.withAlphaComponent(0.90)
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -(width / 2) + 42, y: 0)
        container.addChild(label)

        return container
    }
}

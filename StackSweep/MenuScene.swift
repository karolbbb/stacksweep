//
//  MenuScene.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import SpriteKit

class MenuScene: SKScene {

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        setupBackground()
        setupTitle()
        setupPlayButton()
        setupDecorations()
    }

    // MARK: - Layout

    private func setupBackground() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.fillColor = SKColor(white: 0, alpha: 0.08)
            line.strokeColor = .clear
            line.zPosition = 50
            addChild(line)
        }

        // Neon glow spots in the background
        addGlowSpot(at: CGPoint(x: size.width * 0.2, y: size.height * 0.7),
                     color: SKColor(red: 0.6, green: 0.1, blue: 0.9, alpha: 0.15), radius: 120)
        addGlowSpot(at: CGPoint(x: size.width * 0.8, y: size.height * 0.3),
                     color: SKColor(red: 0.1, green: 0.4, blue: 0.9, alpha: 0.12), radius: 100)
    }

    private func addGlowSpot(at position: CGPoint, color: SKColor, radius: CGFloat) {
        let glow = SKShapeNode(circleOfRadius: radius)
        glow.position = position
        glow.fillColor = color
        glow.strokeColor = .clear
        glow.zPosition = -1
        glow.alpha = 0.6
        glow.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 2.0),
                SKAction.fadeAlpha(to: 0.6, duration: 2.0)
            ])
        ))
        addChild(glow)
    }

    private func setupTitle() {
        let title = SKLabelNode(text: "STACK")
        title.fontName = "Menlo-Bold"
        title.fontSize = 52
        title.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        title.zPosition = 10
        addChild(title)

        let subtitle = SKLabelNode(text: "SWEEP")
        subtitle.fontName = "Menlo-Bold"
        subtitle.fontSize = 52
        subtitle.fontColor = SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 55)
        subtitle.zPosition = 10
        addChild(subtitle)

        // Subtle glow behind title
        let glow = SKLabelNode(text: "STACK")
        glow.fontName = "Menlo-Bold"
        glow.fontSize = 52
        glow.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.3)
        glow.position = CGPoint(x: title.position.x + 2, y: title.position.y - 2)
        glow.zPosition = 9
        addChild(glow)
    }

    private func setupPlayButton() {
        let buttonWidth: CGFloat = 200
        let buttonHeight: CGFloat = 56
        let buttonY = size.height * 0.35

        let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 8)
        bg.position = CGPoint(x: size.width / 2, y: buttonY)
        bg.fillColor = SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1)
        bg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8)
        bg.lineWidth = 2
        bg.zPosition = 10
        bg.name = "playButton"
        addChild(bg)

        let label = SKLabelNode(text: "PLAY")
        label.fontName = "Menlo-Bold"
        label.fontSize = 26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = bg.position
        label.zPosition = 11
        label.name = "playButton"
        addChild(label)

        // Pulse animation
        bg.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.04, duration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ])
        ))
    }

    private func setupDecorations() {
        // Small colored blocks scattered as decoration
        let colors: [SKColor] = [
            SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1),
            SKColor(red: 0.3, green: 0.75, blue: 0.95, alpha: 1),
            SKColor(red: 0.35, green: 0.9, blue: 0.5, alpha: 1),
            SKColor(red: 0.95, green: 0.8, blue: 0.25, alpha: 1)
        ]

        let positions: [(CGFloat, CGFloat, CGFloat)] = [
            (0.15, 0.85, -12), (0.88, 0.78, 8), (0.12, 0.22, 15),
            (0.85, 0.18, -6), (0.5, 0.88, 10), (0.7, 0.12, -18)
        ]

        for (i, pos) in positions.enumerated() {
            let block = SKShapeNode(rectOf: CGSize(width: 22, height: 22), cornerRadius: 3)
            block.position = CGPoint(x: size.width * pos.0, y: size.height * pos.1)
            block.fillColor = colors[i % colors.count]
            block.strokeColor = block.fillColor.withAlphaComponent(0.5)
            block.lineWidth = 1.5
            block.zPosition = 2
            block.zRotation = pos.2 * .pi / 180
            block.alpha = 0.5
            addChild(block)

            block.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.25, duration: Double.random(in: 1.5...3.0)),
                    SKAction.fadeAlpha(to: 0.5, duration: Double.random(in: 1.5...3.0))
                ])
            ))
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        if tapped.contains(where: { $0.name == "playButton" }) {
            let game = GameScene(size: size)
            game.scaleMode = scaleMode
            view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.5))
        }
    }
}

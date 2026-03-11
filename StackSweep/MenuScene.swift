//
//  MenuScene.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import SpriteKit

class MenuScene: SKScene {

    private var showingLevels = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        setupScanlines()
        setupGlowSpots()
        setupTitle()
        setupMainButtons()
        setupDecorations()
    }

    // MARK: - Background

    private func setupScanlines() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.fillColor = SKColor(white: 0, alpha: 0.08)
            line.strokeColor = .clear
            line.zPosition = 50
            addChild(line)
        }
    }

    private func setupGlowSpots() {
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

    // MARK: - Title

    private func setupTitle() {
        let title = makeLabel("STACK", size: 52, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        addChild(title)

        let subtitle = makeLabel("SWEEP", size: 52, color: SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1))
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.72 - 55)
        addChild(subtitle)

        let glow = makeLabel("STACK", size: 52, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.3))
        glow.position = CGPoint(x: title.position.x + 2, y: title.position.y - 2)
        glow.zPosition = 9
        addChild(glow)
    }

    // MARK: - Main Buttons

    private func setupMainButtons() {
        addButton(text: "LEVELS", name: "levelsButton",
                  at: CGPoint(x: size.width / 2, y: size.height * 0.42),
                  fillColor: SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1),
                  strokeColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8),
                  pulse: true)

        addButton(text: "ENDLESS", name: "endlessButton",
                  at: CGPoint(x: size.width / 2, y: size.height * 0.32),
                  fillColor: SKColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1),
                  strokeColor: SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.7),
                  pulse: false)
    }

    private func addButton(text: String, name: String, at position: CGPoint,
                           fillColor: SKColor, strokeColor: SKColor, pulse: Bool) {
        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 8)
        bg.position = position
        bg.fillColor = fillColor
        bg.strokeColor = strokeColor
        bg.lineWidth = 2
        bg.zPosition = 10
        bg.name = name
        addChild(bg)

        let label = makeLabel(text, size: 22, color: .white)
        label.verticalAlignmentMode = .center
        label.position = position
        label.zPosition = 11
        label.name = name
        addChild(label)

        if pulse {
            bg.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.scale(to: 1.04, duration: 0.8),
                    SKAction.scale(to: 1.0, duration: 0.8)
                ])
            ))
        }
    }

    // MARK: - Level Select Grid

    private func showLevelSelect() {
        showingLevels = true

        // Remove main buttons
        children.filter { $0.name == "levelsButton" || $0.name == "endlessButton" }.forEach { $0.removeFromParent() }

        let unlocked = LevelConfig.maxUnlockedLevel
        let cols = 5
        let btnSize: CGFloat = 48
        let gap: CGFloat = 10
        let gridWidth = CGFloat(cols) * btnSize + CGFloat(cols - 1) * gap
        let startX = (size.width - gridWidth) / 2 + btnSize / 2
        let startY = size.height * 0.44

        for i in 0..<10 {
            let row = i / cols
            let col = i % cols
            let level = i + 1
            let x = startX + CGFloat(col) * (btnSize + gap)
            let y = startY - CGFloat(row) * (btnSize + gap)
            let isUnlocked = level <= unlocked

            let bg = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 6)
            bg.position = CGPoint(x: x, y: y)
            bg.fillColor = isUnlocked
                ? SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1)
                : SKColor(white: 0.2, alpha: 0.5)
            bg.strokeColor = isUnlocked
                ? SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7)
                : SKColor(white: 0.3, alpha: 0.4)
            bg.lineWidth = 2
            bg.zPosition = 10
            bg.name = isUnlocked ? "level_\(level)" : nil
            addChild(bg)

            let label = makeLabel("\(level)", size: 20,
                                 color: isUnlocked ? .white : SKColor(white: 0.4, alpha: 1))
            label.verticalAlignmentMode = .center
            label.position = bg.position
            label.zPosition = 11
            label.name = bg.name
            addChild(label)
        }

        // Back button
        let back = makeLabel("< BACK", size: 18, color: SKColor(white: 0.6, alpha: 1))
        back.position = CGPoint(x: size.width / 2, y: startY - 2 * (btnSize + gap) - 20)
        back.zPosition = 11
        back.name = "backFromLevels"
        addChild(back)
    }

    private func hideLevelSelect() {
        showingLevels = false
        children.filter {
            ($0.name ?? "").hasPrefix("level_") ||
            $0.name == "backFromLevels"
        }.forEach { $0.removeFromParent() }

        // Also remove the locked level bg nodes (no name)
        children.filter { node in
            if let shape = node as? SKShapeNode, node.zPosition == 10, node.name == nil {
                return shape.fillColor == SKColor(white: 0.2, alpha: 0.5)
            }
            return false
        }.forEach { $0.removeFromParent() }

        // Remove any remaining level labels
        children.filter { node in
            if let label = node as? SKLabelNode, node.zPosition == 11, node.name == nil {
                return true
            }
            return false
        }.forEach { $0.removeFromParent() }

        setupMainButtons()
    }

    // MARK: - Decorations

    private func setupDecorations() {
        let colors: [SKColor] = [
            SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1),
            SKColor(red: 0.3, green: 0.75, blue: 0.95, alpha: 1),
            SKColor(red: 0.35, green: 0.9, blue: 0.5, alpha: 1),
            SKColor(red: 0.95, green: 0.8, blue: 0.25, alpha: 1)
        ]
        let positions: [(CGFloat, CGFloat, CGFloat)] = [
            (0.15, 0.88, -12), (0.88, 0.85, 8), (0.12, 0.18, 15),
            (0.85, 0.15, -6), (0.5, 0.92, 10), (0.7, 0.10, -18)
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

    // MARK: - Helpers

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 10
        return label
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        if showingLevels {
            if tapped.contains(where: { $0.name == "backFromLevels" }) {
                hideLevelSelect()
                return
            }
            for node in tapped {
                if let name = node.name, name.hasPrefix("level_"),
                   let num = Int(name.replacingOccurrences(of: "level_", with: "")) {
                    startGame(config: .forLevel(num))
                    return
                }
            }
            return
        }

        if tapped.contains(where: { $0.name == "levelsButton" }) {
            showLevelSelect()
            return
        }

        if tapped.contains(where: { $0.name == "endlessButton" }) {
            startGame(config: .endless)
        }
    }

    private func startGame(config: LevelConfig) {
        SoundManager.shared.play(.select)
        let game = GameScene(size: size, config: config)
        game.scaleMode = scaleMode
        view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.5))
    }
}

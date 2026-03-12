//
//  MenuScene.swift
//  StackSweep
//

import SpriteKit

class MenuScene: SKScene {

    private var showingLevels = false
    private var showingStats = false
    private var coinLabel: SKLabelNode!
    private var dailyRewardShown = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        setupScanlines()
        setupGlowSpots()
        setupTitle()
        setupCoinDisplay()
        setupMainButtons()
        setupDecorations()
        checkDailyReward()
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
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.76)
        addChild(title)

        let subtitle = makeLabel("SWEEP", size: 52, color: SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1))
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.76 - 55)
        addChild(subtitle)

        let glow = makeLabel("STACK", size: 52, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.3))
        glow.position = CGPoint(x: title.position.x + 2, y: title.position.y - 2)
        glow.zPosition = 9
        addChild(glow)
    }

    // MARK: - Coin Display

    private func setupCoinDisplay() {
        let coinBg = SKShapeNode(rectOf: CGSize(width: 110, height: 32), cornerRadius: 16)
        coinBg.position = CGPoint(x: size.width / 2, y: size.height * 0.76 - 115)
        coinBg.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 0.9)
        coinBg.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.5)
        coinBg.lineWidth = 1.5
        coinBg.zPosition = 10
        addChild(coinBg)

        coinLabel = makeLabel("🪙 \(PlayerData.shared.coins)", size: 16, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        coinLabel.verticalAlignmentMode = .center
        coinLabel.position = coinBg.position
        coinLabel.zPosition = 11
        addChild(coinLabel)
    }

    // MARK: - Main Buttons

    private func setupMainButtons() {
        let baseY = size.height * 0.46

        addButton(text: "LEVELS", name: "levelsButton",
                  at: CGPoint(x: size.width / 2, y: baseY),
                  fillColor: SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1),
                  strokeColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.8),
                  width: 200, pulse: true)

        addButton(text: "ENDLESS", name: "endlessButton",
                  at: CGPoint(x: size.width / 2, y: baseY - 60),
                  fillColor: SKColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1),
                  strokeColor: SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.7),
                  width: 200, pulse: false)

        // High score under endless
        let highScore = PlayerData.shared.endlessHighScore
        if highScore > 0 {
            let hs = makeLabel("BEST: \(highScore)", size: 12, color: SKColor(white: 0.4, alpha: 1))
            hs.position = CGPoint(x: size.width / 2, y: baseY - 85)
            hs.name = "mainUI"
            addChild(hs)
        }

        addButton(text: "🛒 SHOP", name: "shopButton",
                  at: CGPoint(x: size.width / 2 - 55, y: baseY - 130),
                  fillColor: SKColor(red: 0.2, green: 0.7, blue: 0.35, alpha: 1),
                  strokeColor: SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.7),
                  width: 95, pulse: false)

        addButton(text: "📊 STATS", name: "statsButton",
                  at: CGPoint(x: size.width / 2 + 55, y: baseY - 130),
                  fillColor: SKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1),
                  strokeColor: SKColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 0.7),
                  width: 95, pulse: false)

        // Total stars display
        let totalStars = (1...10).reduce(0) { $0 + PlayerData.shared.starRating(for: $1) }
        if totalStars > 0 {
            let starText = makeLabel("⭐ \(totalStars)/30", size: 13, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.7))
            starText.position = CGPoint(x: size.width / 2, y: baseY - 162)
            starText.name = "mainUI"
            addChild(starText)
        }

        // Daily streak display
        let streak = PlayerData.shared.currentStreak
        if streak > 0 {
            let streakText = makeLabel("🔥 \(streak) DAY STREAK", size: 13, color: SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.8))
            streakText.position = CGPoint(x: size.width / 2, y: baseY - 182)
            streakText.name = "mainUI"
            addChild(streakText)
        }
    }

    private func addButton(text: String, name: String, at position: CGPoint,
                           fillColor: SKColor, strokeColor: SKColor, width: CGFloat, pulse: Bool) {
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 50), cornerRadius: 8)
        bg.position = position
        bg.fillColor = fillColor
        bg.strokeColor = strokeColor
        bg.lineWidth = 2
        bg.zPosition = 10
        bg.name = name
        addChild(bg)

        let label = makeLabel(text, size: 18, color: .white)
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

    // MARK: - Daily Reward

    private func checkDailyReward() {
        let result = PlayerData.shared.checkDailyStreak()
        guard result.isNewDay, !PlayerData.shared.hasClaimedToday else { return }

        run(SKAction.wait(forDuration: 0.6)) { [weak self] in
            self?.showDailyRewardPopup(reward: result.reward)
        }
    }

    private func showDailyRewardPopup(reward: Int) {
        dailyRewardShown = true
        let overlay = SKNode()
        overlay.name = "dailyOverlay"
        overlay.zPosition = 80

        let bg = SKShapeNode(rectOf: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.1, alpha: 0.85)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let card = SKShapeNode(rectOf: CGSize(width: 260, height: 280), cornerRadius: 14)
        card.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1)
        card.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.7)
        card.lineWidth = 2
        overlay.addChild(card)

        let streak = PlayerData.shared.currentStreak
        let title = makeLabel("DAILY REWARD!", size: 22, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        title.position = CGPoint(x: 0, y: 90)
        title.zPosition = 81
        card.addChild(title)

        let fireLabel = makeLabel("🔥 DAY \(streak)", size: 28, color: SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1))
        fireLabel.position = CGPoint(x: 0, y: 45)
        fireLabel.zPosition = 81
        card.addChild(fireLabel)

        let coinText = makeLabel("🪙 +\(reward)", size: 36, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        coinText.position = CGPoint(x: 0, y: -5)
        coinText.zPosition = 81
        card.addChild(coinText)

        // Streak progress dots (7 days)
        let dotSize: CGFloat = 18
        let dotGap: CGFloat = 6
        let totalDotsWidth = 7 * dotSize + 6 * dotGap
        let dotsStartX = -totalDotsWidth / 2 + dotSize / 2
        for i in 0..<7 {
            let dot = SKShapeNode(circleOfRadius: dotSize / 2)
            dot.position = CGPoint(x: dotsStartX + CGFloat(i) * (dotSize + dotGap), y: -50)
            let dayDone = i < (streak % 8 == 0 ? 7 : streak % 8)
            dot.fillColor = dayDone
                ? SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1)
                : SKColor(white: 0.2, alpha: 0.5)
            dot.strokeColor = dayDone
                ? SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.7)
                : SKColor(white: 0.3, alpha: 0.4)
            dot.lineWidth = 1.5
            dot.zPosition = 81
            card.addChild(dot)
        }

        let claimBg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 8)
        claimBg.position = CGPoint(x: 0, y: -95)
        claimBg.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.35, alpha: 1)
        claimBg.strokeColor = SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.7)
        claimBg.lineWidth = 2
        claimBg.zPosition = 81
        claimBg.name = "claimDaily"
        card.addChild(claimBg)

        let claimLabel = makeLabel("CLAIM", size: 20, color: .white)
        claimLabel.verticalAlignmentMode = .center
        claimLabel.position = claimBg.position
        claimLabel.zPosition = 82
        claimLabel.name = "claimDaily"
        card.addChild(claimLabel)

        addChild(overlay)

        card.setScale(0.5)
        card.alpha = 0
        card.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.35),
            SKAction.fadeIn(withDuration: 0.25)
        ]))
    }

    // MARK: - Stats Overlay

    private func showStatsOverlay() {
        showingStats = true
        let overlay = SKNode()
        overlay.name = "statsOverlay"
        overlay.zPosition = 80

        let bg = SKShapeNode(rectOf: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.1, alpha: 0.85)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let card = SKShapeNode(rectOf: CGSize(width: 280, height: 360), cornerRadius: 14)
        card.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1)
        card.strokeColor = SKColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 0.7)
        card.lineWidth = 2
        overlay.addChild(card)

        let title = makeLabel("STATISTICS", size: 24, color: SKColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1))
        title.position = CGPoint(x: 0, y: 140)
        title.zPosition = 81
        card.addChild(title)

        let pd = PlayerData.shared
        let stats: [(String, String)] = [
            ("GAMES PLAYED", "\(pd.totalGamesPlayed)"),
            ("TOTAL LINES", "\(pd.totalLinesCleared)"),
            ("HIGHEST COMBO", "x\(pd.highestCombo)"),
            ("ENDLESS BEST", "\(pd.endlessHighScore)"),
            ("COINS EARNED", "\(pd.totalCoinsEarned)"),
            ("DAY STREAK", "🔥 \(pd.currentStreak)"),
        ]

        for (i, stat) in stats.enumerated() {
            let y: CGFloat = 90 - CGFloat(i) * 36
            let nameLabel = makeLabel(stat.0, size: 13, color: SKColor(white: 0.5, alpha: 1))
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -115, y: y)
            nameLabel.zPosition = 81
            card.addChild(nameLabel)

            let valueLabel = makeLabel(stat.1, size: 15, color: .white)
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.position = CGPoint(x: 115, y: y)
            valueLabel.zPosition = 81
            card.addChild(valueLabel)
        }

        let closeBg = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 6)
        closeBg.position = CGPoint(x: 0, y: -140)
        closeBg.fillColor = SKColor(red: 0.2, green: 0.18, blue: 0.35, alpha: 1)
        closeBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        closeBg.lineWidth = 2
        closeBg.zPosition = 81
        closeBg.name = "closeStats"
        card.addChild(closeBg)

        let closeLabel = makeLabel("CLOSE", size: 16, color: SKColor(white: 0.7, alpha: 1))
        closeLabel.verticalAlignmentMode = .center
        closeLabel.position = closeBg.position
        closeLabel.zPosition = 82
        closeLabel.name = "closeStats"
        card.addChild(closeLabel)

        addChild(overlay)
    }

    // MARK: - Level Select Grid

    private func showLevelSelect() {
        showingLevels = true
        removeMainUI()

        let unlocked = LevelConfig.maxUnlockedLevel
        let cols = 5
        let btnSize: CGFloat = 48
        let gap: CGFloat = 10
        let gridWidth = CGFloat(cols) * btnSize + CGFloat(cols - 1) * gap
        let startX = (size.width - gridWidth) / 2 + btnSize / 2
        let startY = size.height * 0.48

        for i in 0..<10 {
            let row = i / cols
            let col = i % cols
            let level = i + 1
            let x = startX + CGFloat(col) * (btnSize + gap)
            let y = startY - CGFloat(row) * (btnSize + gap + 10)
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
            bg.name = isUnlocked ? "level_\(level)" : "levelGrid"
            addChild(bg)

            let label = makeLabel("\(level)", size: 20,
                                 color: isUnlocked ? .white : SKColor(white: 0.4, alpha: 1))
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: x, y: y + 4)
            label.zPosition = 11
            label.name = isUnlocked ? "level_\(level)" : "levelGrid"
            addChild(label)

            // Stars display under each level
            let stars = PlayerData.shared.starRating(for: level)
            let starY = y - btnSize / 2 - 7
            let starSpacing: CGFloat = 12
            for s in 0..<3 {
                let starLabel = makeLabel(s < stars ? "★" : "☆", size: 10,
                                         color: s < stars ? SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1) : SKColor(white: 0.3, alpha: 0.6))
                starLabel.position = CGPoint(x: x - starSpacing + CGFloat(s) * starSpacing, y: starY)
                starLabel.zPosition = 11
                starLabel.name = "levelGrid"
                addChild(starLabel)
            }
        }

        let back = makeLabel("< BACK", size: 18, color: SKColor(white: 0.6, alpha: 1))
        back.position = CGPoint(x: size.width / 2, y: startY - 2.5 * (btnSize + gap + 10) - 10)
        back.zPosition = 11
        back.name = "backFromLevels"
        addChild(back)
    }

    private func hideLevelSelect() {
        showingLevels = false
        children.filter {
            let n = $0.name ?? ""
            return n.hasPrefix("level_") || n == "backFromLevels" || n == "levelGrid"
        }.forEach { $0.removeFromParent() }

        // Remove locked level nodes (unnamed shape nodes at z=10)
        children.filter { node in
            if node is SKShapeNode, node.zPosition == 10, node.name == nil {
                return true
            }
            return false
        }.forEach { $0.removeFromParent() }

        setupMainButtons()
    }

    private func removeMainUI() {
        children.filter {
            let n = $0.name ?? ""
            return n == "levelsButton" || n == "endlessButton" || n == "shopButton" || n == "statsButton" || n == "mainUI"
        }.forEach { $0.removeFromParent() }
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
            (0.15, 0.92, -12), (0.88, 0.89, 8), (0.12, 0.14, 15),
            (0.85, 0.12, -6), (0.5, 0.96, 10), (0.7, 0.08, -18)
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

        // Daily reward popup
        if dailyRewardShown {
            if tapped.contains(where: { $0.name == "claimDaily" }) {
                let earned = PlayerData.shared.claimDailyReward()
                SoundManager.shared.play(.coin)
                childNode(withName: "dailyOverlay")?.removeFromParent()
                dailyRewardShown = false
                coinLabel.text = "🪙 \(PlayerData.shared.coins)"
                if earned > 0 {
                    showCoinPopup("+\(earned)", at: coinLabel.position)
                }
            }
            return
        }

        // Stats overlay
        if showingStats {
            if tapped.contains(where: { $0.name == "closeStats" }) {
                childNode(withName: "statsOverlay")?.removeFromParent()
                showingStats = false
            }
            return
        }

        // Level select
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

        // Main menu buttons
        if tapped.contains(where: { $0.name == "levelsButton" }) {
            SoundManager.shared.play(.select)
            showLevelSelect()
            return
        }

        if tapped.contains(where: { $0.name == "endlessButton" }) {
            startGame(config: .endless)
            return
        }

        if tapped.contains(where: { $0.name == "shopButton" }) {
            SoundManager.shared.play(.select)
            let shop = ShopScene(size: size)
            shop.scaleMode = scaleMode
            view?.presentScene(shop, transition: SKTransition.fade(withDuration: 0.3))
            return
        }

        if tapped.contains(where: { $0.name == "statsButton" }) {
            SoundManager.shared.play(.select)
            showStatsOverlay()
            return
        }
    }

    private func startGame(config: LevelConfig) {
        SoundManager.shared.play(.select)
        let game = GameScene(size: size, config: config)
        game.scaleMode = scaleMode
        view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.5))
    }

    private func showCoinPopup(_ text: String, at position: CGPoint) {
        let label = makeLabel(text, size: 18, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        label.position = CGPoint(x: position.x, y: position.y - 25)
        label.zPosition = 60
        addChild(label)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 30, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}

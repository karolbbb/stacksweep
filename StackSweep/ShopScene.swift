//
//  ShopScene.swift
//  StackSweep
//

import SpriteKit

class ShopScene: SKScene {

    private enum Tab { case powerups, themes }
    private var currentTab: Tab = .powerups
    private var coinLabel: SKLabelNode!
    private var contentNode: SKNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        setupBackground()
        setupHeader()
        setupTabs()
        contentNode = SKNode()
        addChild(contentNode)
        showPowerUps()
    }

    // MARK: - Background

    private func setupBackground() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.fillColor = SKColor(white: 0, alpha: 0.07)
            line.strokeColor = .clear
            line.zPosition = 50
            addChild(line)
        }
    }

    // MARK: - Header

    private func setupHeader() {
        let back = makeLabel("< BACK", size: 18, color: SKColor(white: 0.6, alpha: 1))
        back.horizontalAlignmentMode = .left
        back.position = CGPoint(x: 16, y: size.height - 36)
        back.name = "backButton"
        addChild(back)

        let title = makeLabel("SHOP", size: 32, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        title.position = CGPoint(x: size.width / 2, y: size.height - 40)
        addChild(title)

        let coinBg = SKShapeNode(rectOf: CGSize(width: 100, height: 30), cornerRadius: 15)
        coinBg.position = CGPoint(x: size.width / 2, y: size.height - 72)
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

    // MARK: - Tabs

    private func setupTabs() {
        let tabY = size.height - 112
        let tabW: CGFloat = size.width / 2 - 20

        addTabButton(text: "POWER-UPS", name: "tabPowerups",
                     at: CGPoint(x: size.width * 0.28, y: tabY), width: tabW, active: true)
        addTabButton(text: "THEMES", name: "tabThemes",
                     at: CGPoint(x: size.width * 0.72, y: tabY), width: tabW, active: false)
    }

    private func addTabButton(text: String, name: String, at pos: CGPoint, width: CGFloat, active: Bool) {
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 38), cornerRadius: 6)
        bg.position = pos
        bg.fillColor = active
            ? SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1)
            : SKColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 0.8)
        bg.strokeColor = active
            ? SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7)
            : SKColor(white: 0.3, alpha: 0.4)
        bg.lineWidth = 1.5
        bg.zPosition = 10
        bg.name = name
        addChild(bg)

        let label = makeLabel(text, size: 15, color: active ? .white : SKColor(white: 0.5, alpha: 1))
        label.verticalAlignmentMode = .center
        label.position = pos
        label.zPosition = 11
        label.name = name
        addChild(label)
    }

    private func switchToTab(_ tab: Tab) {
        guard tab != currentTab else { return }
        currentTab = tab
        children.filter { ($0.name ?? "").hasPrefix("tab") }.forEach { $0.removeFromParent() }
        setupTabs()
        contentNode.removeAllChildren()
        switch tab {
        case .powerups: showPowerUps()
        case .themes:   showThemes()
        }
    }

    private func updateTabAppearance() {
        children.filter { ($0.name ?? "").hasPrefix("tab") }.forEach { $0.removeFromParent() }
        let tabY = size.height - 112
        let tabW: CGFloat = size.width / 2 - 20
        addTabButton(text: "POWER-UPS", name: "tabPowerups",
                     at: CGPoint(x: size.width * 0.28, y: tabY), width: tabW, active: currentTab == .powerups)
        addTabButton(text: "THEMES", name: "tabThemes",
                     at: CGPoint(x: size.width * 0.72, y: tabY), width: tabW, active: currentTab == .themes)
    }

    // MARK: - Power-Ups Grid

    private func showPowerUps() {
        let startY = size.height - 170
        let cardH: CGFloat = 90
        let gap: CGFloat = 12
        let cardW: CGFloat = size.width - 40

        for (i, type) in PowerUpType.allCases.enumerated() {
            let y = startY - CGFloat(i) * (cardH + gap)
            let owned = PlayerData.shared.powerUpCount(for: type.rawValue)
            addPowerUpCard(type: type, owned: owned, at: CGPoint(x: size.width / 2, y: y), width: cardW, height: cardH)
        }
    }

    private func addPowerUpCard(type: PowerUpType, owned: Int, at pos: CGPoint, width: CGFloat, height: CGFloat) {
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        card.position = pos
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 0.95)
        card.strokeColor = type.color.withAlphaComponent(0.4)
        card.lineWidth = 1.5
        card.zPosition = 10
        contentNode.addChild(card)

        let icon = makeLabel(type.icon, size: 32, color: .white)
        icon.position = CGPoint(x: -width / 2 + 35, y: 6)
        icon.zPosition = 11
        card.addChild(icon)

        let nameLabel = makeLabel(type.displayName, size: 17, color: type.color)
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width / 2 + 65, y: 14)
        nameLabel.zPosition = 11
        card.addChild(nameLabel)

        let desc = makeLabel(type.description, size: 12, color: SKColor(white: 0.5, alpha: 1))
        desc.horizontalAlignmentMode = .left
        desc.position = CGPoint(x: -width / 2 + 65, y: -6)
        desc.zPosition = 11
        card.addChild(desc)

        let ownedLabel = makeLabel("OWNED: \(owned)", size: 11, color: SKColor(white: 0.45, alpha: 1))
        ownedLabel.horizontalAlignmentMode = .left
        ownedLabel.position = CGPoint(x: -width / 2 + 65, y: -24)
        ownedLabel.zPosition = 11
        card.addChild(ownedLabel)

        let canAfford = PlayerData.shared.coins >= type.price
        let buyBg = SKShapeNode(rectOf: CGSize(width: 80, height: 34), cornerRadius: 6)
        buyBg.position = CGPoint(x: width / 2 - 55, y: 0)
        buyBg.fillColor = canAfford
            ? SKColor(red: 0.2, green: 0.7, blue: 0.35, alpha: 1)
            : SKColor(white: 0.25, alpha: 0.6)
        buyBg.strokeColor = canAfford
            ? SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.7)
            : SKColor(white: 0.35, alpha: 0.4)
        buyBg.lineWidth = 1.5
        buyBg.zPosition = 11
        buyBg.name = "buy_\(type.rawValue)"
        card.addChild(buyBg)

        let priceLabel = makeLabel("🪙 \(type.price)", size: 14, color: canAfford ? .white : SKColor(white: 0.45, alpha: 1))
        priceLabel.verticalAlignmentMode = .center
        priceLabel.position = buyBg.position
        priceLabel.zPosition = 12
        priceLabel.name = "buy_\(type.rawValue)"
        card.addChild(priceLabel)
    }

    // MARK: - Themes Grid

    private func showThemes() {
        let startY = size.height - 170
        let cardH: CGFloat = 80
        let gap: CGFloat = 12
        let cardW: CGFloat = size.width - 40
        let owned = PlayerData.shared.ownedThemes
        let equipped = PlayerData.shared.equippedTheme

        for (i, theme) in ThemePack.all.enumerated() {
            let y = startY - CGFloat(i) * (cardH + gap)
            let isOwned = owned.contains(theme.id)
            let isEquipped = theme.id == equipped
            addThemeCard(theme: theme, isOwned: isOwned, isEquipped: isEquipped,
                        at: CGPoint(x: size.width / 2, y: y), width: cardW, height: cardH)
        }
    }

    private func addThemeCard(theme: ThemePack, isOwned: Bool, isEquipped: Bool,
                              at pos: CGPoint, width: CGFloat, height: CGFloat) {
        let card = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        card.position = pos
        card.fillColor = theme.boardFill
        card.strokeColor = isEquipped ? theme.accentColor : theme.boardStroke
        card.lineWidth = isEquipped ? 2.5 : 1.5
        card.zPosition = 10
        contentNode.addChild(card)

        // Color preview swatches
        let swatchSize: CGFloat = 22
        let swatchGap: CGFloat = 4
        for (j, color) in theme.blockColors.enumerated() {
            let swatch = SKShapeNode(rectOf: CGSize(width: swatchSize, height: swatchSize), cornerRadius: 3)
            swatch.position = CGPoint(x: -width / 2 + 30 + CGFloat(j) * (swatchSize + swatchGap), y: 8)
            swatch.fillColor = color
            swatch.strokeColor = color.withAlphaComponent(theme.blockGlowAlpha)
            swatch.lineWidth = 1.5
            swatch.zPosition = 11
            card.addChild(swatch)
        }

        let nameLabel = makeLabel(theme.name, size: 16, color: theme.accentColor)
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width / 2 + 20, y: -18)
        nameLabel.zPosition = 11
        card.addChild(nameLabel)

        let btnW: CGFloat = 90
        let btnBg = SKShapeNode(rectOf: CGSize(width: btnW, height: 34), cornerRadius: 6)
        btnBg.position = CGPoint(x: width / 2 - 60, y: 0)
        btnBg.zPosition = 11

        if isEquipped {
            btnBg.fillColor = SKColor(white: 0.2, alpha: 0.6)
            btnBg.strokeColor = theme.accentColor.withAlphaComponent(0.4)
            btnBg.lineWidth = 1.5
            let label = makeLabel("EQUIPPED", size: 12, color: theme.accentColor)
            label.verticalAlignmentMode = .center
            label.position = btnBg.position
            label.zPosition = 12
            card.addChild(label)
        } else if isOwned {
            btnBg.fillColor = SKColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1)
            btnBg.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.7)
            btnBg.lineWidth = 1.5
            btnBg.name = "equip_\(theme.id)"
            let label = makeLabel("EQUIP", size: 14, color: .white)
            label.verticalAlignmentMode = .center
            label.position = btnBg.position
            label.zPosition = 12
            label.name = "equip_\(theme.id)"
            card.addChild(label)
        } else {
            let canAfford = PlayerData.shared.coins >= theme.price
            btnBg.fillColor = canAfford
                ? SKColor(red: 0.2, green: 0.7, blue: 0.35, alpha: 1)
                : SKColor(white: 0.25, alpha: 0.6)
            btnBg.strokeColor = canAfford
                ? SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.7)
                : SKColor(white: 0.35, alpha: 0.4)
            btnBg.lineWidth = 1.5
            btnBg.name = "buyTheme_\(theme.id)"
            let label = makeLabel("🪙 \(theme.price)", size: 14, color: canAfford ? .white : SKColor(white: 0.45, alpha: 1))
            label.verticalAlignmentMode = .center
            label.position = btnBg.position
            label.zPosition = 12
            label.name = "buyTheme_\(theme.id)"
            card.addChild(label)
        }

        card.addChild(btnBg)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        if tapped.contains(where: { $0.name == "backButton" }) {
            goToMenu()
            return
        }

        if tapped.contains(where: { $0.name == "tabPowerups" }) {
            SoundManager.shared.play(.select)
            switchToTab(.powerups)
            updateTabAppearance()
            return
        }

        if tapped.contains(where: { $0.name == "tabThemes" }) {
            SoundManager.shared.play(.select)
            switchToTab(.themes)
            updateTabAppearance()
            return
        }

        for node in tapped {
            guard let name = node.name else { continue }

            if name.hasPrefix("buy_") {
                let typeRaw = String(name.dropFirst(4))
                guard let type = PowerUpType(rawValue: typeRaw) else { continue }
                if PlayerData.shared.spendCoins(type.price) {
                    PlayerData.shared.addPowerUp(type.rawValue)
                    SoundManager.shared.play(.purchase)
                    refreshContent()
                }
                return
            }

            if name.hasPrefix("equip_") {
                let themeId = String(name.dropFirst(6))
                PlayerData.shared.equippedTheme = themeId
                SoundManager.shared.play(.select)
                refreshContent()
                return
            }

            if name.hasPrefix("buyTheme_") {
                let themeId = String(name.dropFirst(9))
                guard let theme = ThemePack.all.first(where: { $0.id == themeId }) else { continue }
                if PlayerData.shared.spendCoins(theme.price) {
                    PlayerData.shared.unlockTheme(theme.id)
                    PlayerData.shared.equippedTheme = theme.id
                    SoundManager.shared.play(.purchase)
                    refreshContent()
                }
                return
            }
        }
    }

    private func refreshContent() {
        coinLabel.text = "🪙 \(PlayerData.shared.coins)"
        contentNode.removeAllChildren()
        switch currentTab {
        case .powerups: showPowerUps()
        case .themes:   showThemes()
        }
    }

    private func goToMenu() {
        let menu = MenuScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.3))
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 10
        return label
    }
}

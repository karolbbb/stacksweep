//
//  GameScene.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import SpriteKit

// MARK: - Block Color

/// The four block colors available in the game.
enum BlockColor: Int, CaseIterable {
    case red, blue, green, yellow

    var skColor: SKColor {
        switch self {
        case .red:    return SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1)
        case .blue:   return SKColor(red: 0.3, green: 0.75, blue: 0.95, alpha: 1)
        case .green:  return SKColor(red: 0.35, green: 0.9, blue: 0.5, alpha: 1)
        case .yellow: return SKColor(red: 0.95, green: 0.8, blue: 0.25, alpha: 1)
        }
    }

    var glowColor: SKColor {
        skColor.withAlphaComponent(0.5)
    }

    static var random: BlockColor {
        allCases.randomElement()!
    }
}

// MARK: - Cell

/// State of a single cell on the board.
enum Cell: Equatable {
    case empty
    case block(BlockColor)
    case junk

    var isOccupied: Bool { self != .empty }
}

// MARK: - GameScene

class GameScene: SKScene {

    // MARK: - Constants

    private let gridRows = 6
    private let gridCols = 6
    private let cellSize: CGFloat = 48
    private let cellGap: CGFloat = 4
    private let roundDuration: TimeInterval = 90
    private let junkColor = SKColor(red: 0.28, green: 0.25, blue: 0.35, alpha: 1)

    // MARK: - State

    private var board: [[Cell]] = []
    private var tiles: [[SKSpriteNode]] = []
    private var boardOrigin: CGPoint = .zero

    private var score = 0
    private var combo = 1
    private var timeRemaining: TimeInterval = 90
    private var lastUpdateTime: TimeInterval = 0
    private var selectedCell: (row: Int, col: Int)?
    private var sweepAvailable = true
    private var sweepSelecting = false
    private var isGameOver = false

    // MARK: - UI Nodes

    private var scoreLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var sweepButton: SKNode!
    private var selectionIndicator: SKShapeNode?
    private var boardContainer: SKNode!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        timeRemaining = roundDuration

        setupScanlines()
        setupBoard()
        setupHUD()
        populateInitialBoard()
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        if lastUpdateTime > 0 {
            let dt = currentTime - lastUpdateTime
            timeRemaining -= dt
            if timeRemaining <= 0 {
                timeRemaining = 0
                endGame()
            }
        }
        lastUpdateTime = currentTime
        timerLabel.text = formatTime(timeRemaining)
    }

    // MARK: - Setup

    private func setupScanlines() {
        for y in stride(from: 0, to: size.height, by: 3) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 1))
            line.position = CGPoint(x: size.width / 2, y: y)
            line.fillColor = SKColor(white: 0, alpha: 0.07)
            line.strokeColor = .clear
            line.zPosition = 90
            addChild(line)
        }
    }

    private func setupBoard() {
        board = Array(repeating: Array(repeating: Cell.empty, count: gridCols), count: gridRows)
        tiles = Array(repeating: [], count: gridRows)

        let totalW = CGFloat(gridCols) * cellSize + CGFloat(gridCols - 1) * cellGap
        let totalH = CGFloat(gridRows) * cellSize + CGFloat(gridRows - 1) * cellGap
        boardOrigin = CGPoint(
            x: (size.width - totalW) / 2 + cellSize / 2,
            y: (size.height - totalH) / 2 + cellSize / 2 - 20
        )

        boardContainer = SKNode()
        addChild(boardContainer)

        // Board backdrop
        let backdrop = SKShapeNode(rectOf: CGSize(width: totalW + 16, height: totalH + 16), cornerRadius: 8)
        backdrop.position = CGPoint(x: size.width / 2, y: boardOrigin.y + totalH / 2 - cellSize / 2)
        backdrop.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.18, alpha: 0.9)
        backdrop.strokeColor = SKColor(red: 0.3, green: 0.25, blue: 0.5, alpha: 0.6)
        backdrop.lineWidth = 2
        backdrop.zPosition = -1
        boardContainer.addChild(backdrop)

        for row in 0..<gridRows {
            var rowTiles: [SKSpriteNode] = []
            for col in 0..<gridCols {
                let tile = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
                tile.position = positionFor(row: row, col: col)
                tile.zPosition = 1
                tile.name = "tile"
                tile.userData = NSMutableDictionary(dictionary: ["row": row, "col": col])

                let border = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
                border.strokeColor = SKColor(white: 0.25, alpha: 0.4)
                border.lineWidth = 1
                border.fillColor = SKColor(white: 0.15, alpha: 0.2)
                border.zPosition = -0.5
                border.name = "border"
                tile.addChild(border)

                boardContainer.addChild(tile)
                rowTiles.append(tile)
            }
            tiles[row] = rowTiles
        }
    }

    private func setupHUD() {
        // Score
        let scoreTitle = makeLabel("SCORE", size: 14, color: SKColor(white: 0.5, alpha: 1))
        scoreTitle.position = CGPoint(x: size.width / 2 - 70, y: size.height - 70)
        addChild(scoreTitle)

        scoreLabel = makeLabel("0", size: 32, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        scoreLabel.position = CGPoint(x: size.width / 2 - 70, y: size.height - 105)
        addChild(scoreLabel)

        // Combo
        let comboTitle = makeLabel("COMBO", size: 14, color: SKColor(white: 0.5, alpha: 1))
        comboTitle.position = CGPoint(x: size.width / 2 + 70, y: size.height - 70)
        addChild(comboTitle)

        comboLabel = makeLabel("x1", size: 32, color: SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1))
        comboLabel.position = CGPoint(x: size.width / 2 + 70, y: size.height - 105)
        addChild(comboLabel)

        // Timer
        timerLabel = makeLabel(formatTime(roundDuration), size: 22, color: .white)
        timerLabel.position = CGPoint(x: size.width / 2, y: size.height - 135)
        addChild(timerLabel)

        // Sweep button
        let btnContainer = SKNode()
        btnContainer.position = CGPoint(x: size.width / 2, y: 50)
        btnContainer.name = "sweepButton"
        btnContainer.zPosition = 10
        addChild(btnContainer)
        sweepButton = btnContainer

        let bg = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 6)
        bg.fillColor = SKColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1)
        bg.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 0.7)
        bg.lineWidth = 2
        bg.name = "sweepButton"
        btnContainer.addChild(bg)

        let btnLabel = makeLabel("SWEEP", size: 18, color: .white)
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = .zero
        btnLabel.name = "sweepButton"
        btnContainer.addChild(btnLabel)
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 10
        return label
    }

    /// Places a mix of colored blocks and junk to start the round.
    private func populateInitialBoard() {
        let totalCells = gridRows * gridCols
        let blockCount = Int.random(in: 8...12)
        let junkCount = Int.random(in: 2...4)

        var indices = Array(0..<totalCells).shuffled()

        for _ in 0..<blockCount {
            guard let idx = indices.popLast() else { break }
            let row = idx / gridCols
            let col = idx % gridCols
            board[row][col] = .block(.random)
        }

        for _ in 0..<junkCount {
            guard let idx = indices.popLast() else { break }
            let row = idx / gridCols
            let col = idx % gridCols
            board[row][col] = .junk
        }

        refreshAllTiles()
    }

    // MARK: - Grid Helpers

    private func positionFor(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + CGFloat(col) * (cellSize + cellGap),
            y: boardOrigin.y + CGFloat(row) * (cellSize + cellGap)
        )
    }

    private func cellFromTouch(_ location: CGPoint) -> (row: Int, col: Int)? {
        for node in nodes(at: location) {
            if node.name == "tile",
               let data = node.userData,
               let row = data["row"] as? Int,
               let col = data["col"] as? Int,
               row >= 0, row < gridRows, col >= 0, col < gridCols {
                return (row, col)
            }
        }
        return nil
    }

    private func areAdjacent(_ a: (Int, Int), _ b: (Int, Int)) -> Bool {
        abs(a.0 - b.0) + abs(a.1 - b.1) == 1
    }

    // MARK: - Rendering

    private func refreshAllTiles() {
        for row in 0..<gridRows {
            for col in 0..<gridCols {
                updateTile(row: row, col: col)
            }
        }
    }

    private func updateTile(row: Int, col: Int) {
        let tile = tiles[row][col]
        tile.removeAllActions()

        // Remove old block child if any
        tile.children.filter { $0.name == "blockFill" }.forEach { $0.removeFromParent() }

        let border = tile.childNode(withName: "border") as? SKShapeNode

        switch board[row][col] {
        case .empty:
            border?.fillColor = SKColor(white: 0.15, alpha: 0.2)
            border?.strokeColor = SKColor(white: 0.25, alpha: 0.4)

        case .block(let color):
            let fill = SKShapeNode(rectOf: CGSize(width: cellSize - 4, height: cellSize - 4), cornerRadius: 4)
            fill.fillColor = color.skColor
            fill.strokeColor = color.glowColor
            fill.lineWidth = 2
            fill.zPosition = 1
            fill.name = "blockFill"
            tile.addChild(fill)

            border?.fillColor = .clear
            border?.strokeColor = color.skColor.withAlphaComponent(0.3)

        case .junk:
            let fill = SKShapeNode(rectOf: CGSize(width: cellSize - 4, height: cellSize - 4), cornerRadius: 4)
            fill.fillColor = junkColor
            fill.strokeColor = SKColor(white: 0.4, alpha: 0.4)
            fill.lineWidth = 1.5
            fill.zPosition = 1
            fill.name = "blockFill"
            tile.addChild(fill)

            // Cross pattern to distinguish junk
            let cross1 = SKShapeNode(rectOf: CGSize(width: cellSize * 0.5, height: 2))
            cross1.fillColor = SKColor(white: 0.45, alpha: 0.5)
            cross1.strokeColor = .clear
            cross1.zRotation = .pi / 4
            cross1.zPosition = 2
            cross1.name = "blockFill"
            tile.addChild(cross1)

            let cross2 = SKShapeNode(rectOf: CGSize(width: cellSize * 0.5, height: 2))
            cross2.fillColor = SKColor(white: 0.45, alpha: 0.5)
            cross2.strokeColor = .clear
            cross2.zRotation = -.pi / 4
            cross2.zPosition = 2
            cross2.name = "blockFill"
            tile.addChild(cross2)

            border?.fillColor = .clear
            border?.strokeColor = SKColor(white: 0.3, alpha: 0.4)
        }
    }

    // MARK: - Selection

    private func showSelection(row: Int, col: Int) {
        removeSelection()
        let indicator = SKShapeNode(rectOf: CGSize(width: cellSize + 4, height: cellSize + 4), cornerRadius: 6)
        indicator.strokeColor = .white
        indicator.lineWidth = 2.5
        indicator.fillColor = SKColor(white: 1, alpha: 0.08)
        indicator.zPosition = 5
        indicator.position = positionFor(row: row, col: col)
        indicator.name = "selection"
        boardContainer.addChild(indicator)
        selectionIndicator = indicator

        indicator.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4)
            ])
        ))
    }

    private func removeSelection() {
        selectionIndicator?.removeFromParent()
        selectionIndicator = nil
        selectedCell = nil
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Sweep button: toggle sweep mode on/off
        if nodes(at: location).contains(where: { $0.name == "sweepButton" }) {
            if sweepAvailable {
                if sweepSelecting {
                    cancelSweepMode()
                } else {
                    sweepSelecting = true
                    (sweepButton.children.first as? SKShapeNode)?.fillColor =
                        SKColor(red: 0.9, green: 0.5, blue: 0.15, alpha: 1)
                    if let lbl = sweepButton.children.compactMap({ $0 as? SKLabelNode }).first {
                        lbl.text = "TAP ROW"
                    }
                    removeSelection()
                }
                return
            }
        }

        guard let (row, col) = cellFromTouch(location) else {
            // Tap outside grid while in sweep mode cancels it
            if sweepSelecting { cancelSweepMode() }
            return
        }

        // Sweep mode: clear tapped row
        if sweepSelecting {
            performSweep(row: row)
            return
        }

        // Regular gameplay
        if let sel = selectedCell {
            if sel.row == row && sel.col == col {
                removeSelection()
                return
            }

            // Tap on adjacent empty cell → move selected block there
            if areAdjacent(sel, (row, col)) && board[row][col] == .empty && board[sel.row][sel.col] != .empty && board[sel.row][sel.col] != .junk {
                moveBlock(from: sel, to: (row, col))
                return
            }

            // Tap another block → re-select
            if case .block = board[row][col] {
                selectedCell = (row, col)
                showSelection(row: row, col: col)
                return
            }

            removeSelection()
        } else {
            if case .block = board[row][col] {
                selectedCell = (row, col)
                showSelection(row: row, col: col)
            }
        }
    }

    // MARK: - Move

    private func moveBlock(from src: (row: Int, col: Int), to dst: (row: Int, col: Int)) {
        board[dst.row][dst.col] = board[src.row][src.col]
        board[src.row][src.col] = .empty

        removeSelection()
        updateTile(row: src.row, col: src.col)
        updateTile(row: dst.row, col: dst.col)

        // Animate the move
        let tile = tiles[dst.row][dst.col]
        tile.alpha = 0.5
        tile.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15))

        let cleared = checkAndClearLines()
        if cleared > 0 {
            score += cleared * 10 * combo
            combo += 1
        } else {
            combo = 1
        }
        updateHUD()

        spawnAfterMove()
        checkBoardFull()
    }

    // MARK: - Line Clearing

    /// Checks all rows and columns for same-color completion. Returns total lines cleared.
    /// Collects all matches before clearing so simultaneous row+column clears both count.
    private func checkAndClearLines() -> Int {
        var rowsToClear: [(row: Int, color: BlockColor)] = []
        var colsToClear: [(col: Int, color: BlockColor)] = []

        for row in 0..<gridRows {
            if let color = uniformColorInRow(row) {
                rowsToClear.append((row, color))
            }
        }

        for col in 0..<gridCols {
            if let color = uniformColorInCol(col) {
                colsToClear.append((col, color))
            }
        }

        let cleared = rowsToClear.count + colsToClear.count
        guard cleared > 0 else { return 0 }

        for (row, color) in rowsToClear {
            for col in 0..<gridCols {
                animateClear(row: row, col: col, color: color)
                board[row][col] = .empty
            }
        }

        for (col, color) in colsToClear {
            for row in 0..<gridRows {
                animateClear(row: row, col: col, color: color)
                board[row][col] = .empty
            }
        }

        refreshAllTiles()
        return cleared
    }

    /// Returns the block color if every cell in the row is the same block color (no empty, no junk).
    private func uniformColorInRow(_ row: Int) -> BlockColor? {
        var foundColor: BlockColor?
        for col in 0..<gridCols {
            switch board[row][col] {
            case .empty: return nil
            case .junk: return nil
            case .block(let c):
                if let existing = foundColor, existing != c { return nil }
                foundColor = c
            }
        }
        return foundColor
    }

    private func uniformColorInCol(_ col: Int) -> BlockColor? {
        var foundColor: BlockColor?
        for row in 0..<gridRows {
            switch board[row][col] {
            case .empty: return nil
            case .junk: return nil
            case .block(let c):
                if let existing = foundColor, existing != c { return nil }
                foundColor = c
            }
        }
        return foundColor
    }

    private func animateClear(row: Int, col: Int, color: BlockColor) {
        let pos = positionFor(row: row, col: col)

        let flash = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
        flash.position = pos
        flash.fillColor = color.skColor
        flash.strokeColor = .white
        flash.lineWidth = 2
        flash.zPosition = 20
        flash.alpha = 0.9
        boardContainer.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 1.5, duration: 0.35)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Spawning

    /// After a player move, spawn 1 random colored block and sometimes 1 junk.
    private func spawnAfterMove() {
        var empties = emptyCells()
        guard let idx = empties.indices.randomElement() else { return }
        let (r, c) = empties[idx]
        board[r][c] = .block(.random)
        updateTile(row: r, col: c)
        animateSpawn(row: r, col: c)
        empties.remove(at: idx)

        // 30% chance to also spawn junk
        if Double.random(in: 0...1) < 0.3, let jIdx = empties.indices.randomElement() {
            let (jr, jc) = empties[jIdx]
            board[jr][jc] = .junk
            updateTile(row: jr, col: jc)
            animateSpawn(row: jr, col: jc)
        }
    }

    private func animateSpawn(row: Int, col: Int) {
        let tile = tiles[row][col]
        tile.setScale(0.1)
        tile.run(SKAction.scale(to: 1.0, duration: 0.2))
    }

    private func emptyCells() -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                if board[r][c] == .empty { result.append((r, c)) }
            }
        }
        return result
    }

    // MARK: - Sweep

    private func cancelSweepMode() {
        sweepSelecting = false
        (sweepButton.children.first as? SKShapeNode)?.fillColor =
            SKColor(red: 0.15, green: 0.55, blue: 0.65, alpha: 1)
        if let lbl = sweepButton.children.compactMap({ $0 as? SKLabelNode }).first {
            lbl.text = "SWEEP"
        }
    }

    private func performSweep(row: Int) {
        for col in 0..<gridCols {
            let pos = positionFor(row: row, col: col)
            let flash = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
            flash.position = pos
            flash.fillColor = SKColor.cyan
            flash.strokeColor = .white
            flash.zPosition = 20
            boardContainer.addChild(flash)
            flash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
            board[row][col] = .empty
        }

        score += 6 * combo
        combo += 1
        refreshAllTiles()
        updateHUD()

        sweepSelecting = false
        sweepAvailable = false
        (sweepButton.children.first as? SKShapeNode)?.fillColor = SKColor(white: 0.3, alpha: 0.6)
        if let lbl = sweepButton.children.compactMap({ $0 as? SKLabelNode }).first {
            lbl.text = "USED"
            lbl.fontColor = SKColor(white: 0.5, alpha: 1)
        }
    }

    // MARK: - HUD

    private func updateHUD() {
        scoreLabel.text = "\(score)"
        comboLabel.text = "x\(combo)"

        // Flash combo label on increase
        if combo > 1 {
            comboLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.15)
            ]))
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Game Over

    private func checkBoardFull() {
        if emptyCells().isEmpty { endGame() }
    }

    private func endGame() {
        guard !isGameOver else { return }
        isGameOver = true

        // Darken overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.1, alpha: 0.85)
        overlay.strokeColor = .clear
        overlay.zPosition = 80
        addChild(overlay)

        // Game Over card
        let card = SKShapeNode(rectOf: CGSize(width: 260, height: 280), cornerRadius: 12)
        card.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1)
        card.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 0.7)
        card.lineWidth = 2
        card.zPosition = 85
        addChild(card)

        let gameOverLabel = makeLabel("GAME OVER", size: 28, color: SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1))
        gameOverLabel.position = CGPoint(x: 0, y: 80)
        gameOverLabel.zPosition = 86
        card.addChild(gameOverLabel)

        let finalScore = makeLabel("SCORE: \(score)", size: 32, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        finalScore.position = CGPoint(x: 0, y: 25)
        finalScore.zPosition = 86
        card.addChild(finalScore)

        // Retry button
        let retryBg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 6)
        retryBg.position = CGPoint(x: 0, y: -35)
        retryBg.fillColor = SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1)
        retryBg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7)
        retryBg.lineWidth = 2
        retryBg.zPosition = 86
        retryBg.name = "retry"
        card.addChild(retryBg)

        let retryLabel = makeLabel("RETRY", size: 20, color: .white)
        retryLabel.verticalAlignmentMode = .center
        retryLabel.position = CGPoint(x: 0, y: -35)
        retryLabel.zPosition = 87
        retryLabel.name = "retry"
        card.addChild(retryLabel)

        // Menu button
        let menuBg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 6)
        menuBg.position = CGPoint(x: 0, y: -90)
        menuBg.fillColor = SKColor(red: 0.2, green: 0.18, blue: 0.35, alpha: 1)
        menuBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        menuBg.lineWidth = 2
        menuBg.zPosition = 86
        menuBg.name = "menu"
        card.addChild(menuBg)

        let menuLabel = makeLabel("MENU", size: 20, color: SKColor(white: 0.7, alpha: 1))
        menuLabel.verticalAlignmentMode = .center
        menuLabel.position = CGPoint(x: 0, y: -90)
        menuLabel.zPosition = 87
        menuLabel.name = "menu"
        card.addChild(menuLabel)

        // Override touch handler
        isGameOver = true
    }

    /// Separate touch handler for game-over buttons (checked first in touchesBegan).
    private func handleGameOverTouch(_ location: CGPoint) {
        let tapped = nodes(at: location)

        if tapped.contains(where: { $0.name == "retry" }) {
            let newGame = GameScene(size: size)
            newGame.scaleMode = scaleMode
            view?.presentScene(newGame, transition: SKTransition.fade(withDuration: 0.4))
            return
        }

        if tapped.contains(where: { $0.name == "menu" }) {
            let menu = MenuScene(size: size)
            menu.scaleMode = scaleMode
            view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.4))
        }
    }

    // Override to handle game-over taps
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameOver, let touch = touches.first else { return }
        handleGameOverTouch(touch.location(in: self))
    }
}

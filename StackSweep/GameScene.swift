//
//  GameScene.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import SpriteKit

// MARK: - Block Color

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

    var glowColor: SKColor { skColor.withAlphaComponent(0.5) }

    static func random(from count: Int) -> BlockColor {
        let available = Array(allCases.prefix(max(1, min(count, allCases.count))))
        return available.randomElement()!
    }
}

// MARK: - Cell

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
    private let junkColor = SKColor(red: 0.28, green: 0.25, blue: 0.35, alpha: 1)

    // MARK: - Config

    private let config: LevelConfig

    // MARK: - State

    private var board: [[Cell]] = []
    private var tiles: [[SKSpriteNode]] = []
    private var boardOrigin: CGPoint = .zero

    private var score = 0
    private var combo = 1
    private var linesCleared = 0
    private var timeRemaining: TimeInterval = 90
    private var lastUpdateTime: TimeInterval = 0
    private var selectedCell: (row: Int, col: Int)?
    private var sweepAvailable = true
    private var sweepSelecting = false
    private var isGameOver = false
    private var isShowingQuitPrompt = false

    // Endless mode: difficulty ramps every 3 clears
    private var endlessJunkChance: Double = 0.20
    private var endlessColorCount: Int = 4

    // MARK: - UI Nodes

    private var scoreLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var linesLabel: SKLabelNode!
    private var sweepButton: SKNode!
    private var selectionIndicator: SKShapeNode?
    private var boardContainer: SKNode!
    private var pauseOverlay: SKNode?

    // MARK: - Init

    init(size: CGSize, config: LevelConfig) {
        self.config = config
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.config = .endless
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        timeRemaining = config.roundDuration
        endlessJunkChance = config.junkSpawnChance
        endlessColorCount = config.colorCount

        setupScanlines()
        setupBoard()
        setupHUD()
        populateInitialBoard()
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver, !isShowingQuitPrompt else {
            lastUpdateTime = currentTime
            return
        }
        if lastUpdateTime > 0 {
            let dt = currentTime - lastUpdateTime
            timeRemaining -= dt
            if timeRemaining <= 0 {
                timeRemaining = 0
                endGame(completed: false)
            }
        }
        lastUpdateTime = currentTime
        timerLabel.text = formatTime(timeRemaining)

        // Flash timer red in last 10 seconds
        if timeRemaining <= 10 {
            timerLabel.fontColor = SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
        }
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
            y: (size.height - totalH) / 2 + cellSize / 2
        )

        boardContainer = SKNode()
        addChild(boardContainer)

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
        let totalH = CGFloat(gridRows) * cellSize + CGFloat(gridRows - 1) * cellGap
        let boardTop = boardOrigin.y + totalH - cellSize / 2
        let boardBottom = boardOrigin.y - cellSize / 2
        let hudY = boardTop + 28

        // Level label
        levelLabel = makeLabel(config.displayName, size: 14, color: SKColor(white: 0.5, alpha: 1))
        levelLabel.position = CGPoint(x: size.width / 2, y: hudY + 40)
        addChild(levelLabel)

        // Score
        let scoreTitle = makeLabel("SCORE", size: 12, color: SKColor(white: 0.5, alpha: 1))
        scoreTitle.position = CGPoint(x: size.width / 2 - 65, y: hudY + 18)
        addChild(scoreTitle)

        scoreLabel = makeLabel("0", size: 26, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        scoreLabel.position = CGPoint(x: size.width / 2 - 65, y: hudY - 8)
        addChild(scoreLabel)

        // Combo
        let comboTitle = makeLabel("COMBO", size: 12, color: SKColor(white: 0.5, alpha: 1))
        comboTitle.position = CGPoint(x: size.width / 2 + 65, y: hudY + 18)
        addChild(comboTitle)

        comboLabel = makeLabel("x1", size: 26, color: SKColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1))
        comboLabel.position = CGPoint(x: size.width / 2 + 65, y: hudY - 8)
        addChild(comboLabel)

        // Timer centered
        timerLabel = makeLabel(formatTime(config.roundDuration), size: 20, color: .white)
        timerLabel.position = CGPoint(x: size.width / 2, y: hudY + 2)
        addChild(timerLabel)

        // Lines target (level mode only)
        if !config.isEndless {
            linesLabel = makeLabel("0/\(config.linesToClear)", size: 14, color: SKColor(white: 0.6, alpha: 1))
            linesLabel.position = CGPoint(x: size.width / 2, y: hudY - 18)
            addChild(linesLabel)
        }

        // Sweep button -- centered below board
        let sweepY = boardBottom - 35
        let btnContainer = SKNode()
        btnContainer.position = CGPoint(x: size.width / 2, y: sweepY)
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

        // Back to menu button -- top left
        let backBtn = makeLabel("< MENU", size: 16, color: SKColor(white: 0.5, alpha: 1))
        backBtn.horizontalAlignmentMode = .left
        backBtn.position = CGPoint(x: 16, y: size.height - 36)
        backBtn.zPosition = 10
        backBtn.name = "backButton"
        addChild(backBtn)
    }

    private func makeLabel(_ text: String, size: CGFloat, color: SKColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "Menlo-Bold"
        label.fontSize = size
        label.fontColor = color
        label.zPosition = 10
        return label
    }

    private func populateInitialBoard() {
        let totalCells = gridRows * gridCols
        var indices = Array(0..<totalCells).shuffled()

        for _ in 0..<config.initialBlocks {
            guard let idx = indices.popLast() else { break }
            board[idx / gridCols][idx % gridCols] = .block(BlockColor.random(from: config.colorCount))
        }

        for _ in 0..<config.initialJunk {
            guard let idx = indices.popLast() else { break }
            board[idx / gridCols][idx % gridCols] = .junk
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
            let candidate = node.name == "tile" ? node : node.parent
            if let tile = candidate,
               tile.name == "tile",
               let data = tile.userData,
               let row = data["row"] as? Int,
               let col = data["col"] as? Int,
               row >= 0, row < gridRows, col >= 0, col < gridCols {
                return (row, col)
            }
        }
        let col = Int(round((location.x - boardOrigin.x) / (cellSize + cellGap)))
        let row = Int(round((location.y - boardOrigin.y) / (cellSize + cellGap)))
        if row >= 0, row < gridRows, col >= 0, col < gridCols {
            let tilePos = positionFor(row: row, col: col)
            if abs(location.x - tilePos.x) <= cellSize / 2,
               abs(location.y - tilePos.y) <= cellSize / 2 {
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

            for angle: CGFloat in [.pi / 4, -.pi / 4] {
                let cross = SKShapeNode(rectOf: CGSize(width: cellSize * 0.5, height: 2))
                cross.fillColor = SKColor(white: 0.45, alpha: 0.5)
                cross.strokeColor = .clear
                cross.zRotation = angle
                cross.zPosition = 2
                cross.name = "blockFill"
                tile.addChild(cross)
            }
            border?.fillColor = .clear
            border?.strokeColor = SKColor(white: 0.3, alpha: 0.4)
        }
    }

    // MARK: - Selection

    private func showSelection(row: Int, col: Int) {
        selectionIndicator?.removeFromParent()
        selectionIndicator = nil
        selectedCell = (row, col)

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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        // Handle pause overlay buttons
        if isShowingQuitPrompt {
            if tapped.contains(where: { $0.name == "quitConfirm" }) {
                goToMenu()
            } else if tapped.contains(where: { $0.name == "cancelQuit" }) {
                dismissPauseOverlay()
            }
            return
        }

        // Game over buttons
        if isGameOver {
            handleEndScreenTouch(tapped)
            return
        }

        // Back button
        if tapped.contains(where: { $0.name == "backButton" }) {
            showPauseOverlay()
            return
        }

        // Sweep button
        if tapped.contains(where: { $0.name == "sweepButton" }) {
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
            if sweepSelecting { cancelSweepMode() }
            return
        }

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
            if areAdjacent(sel, (row, col)) && board[row][col] == .empty,
               case .block = board[sel.row][sel.col] {
                moveBlock(from: sel, to: (row, col))
                return
            }
            if case .block = board[row][col] {
                SoundManager.shared.play(.select)
                showSelection(row: row, col: col)
                return
            }
            removeSelection()
        } else {
            if case .block = board[row][col] {
                SoundManager.shared.play(.select)
                showSelection(row: row, col: col)
            }
        }
    }

    // MARK: - Move

    private func moveBlock(from src: (row: Int, col: Int), to dst: (row: Int, col: Int)) {
        board[dst.row][dst.col] = board[src.row][src.col]
        board[src.row][src.col] = .empty

        SoundManager.shared.play(.move)
        removeSelection()
        updateTile(row: src.row, col: src.col)
        updateTile(row: dst.row, col: dst.col)

        let tile = tiles[dst.row][dst.col]
        tile.alpha = 0.5
        tile.run(SKAction.fadeAlpha(to: 1.0, duration: 0.15))

        let cleared = checkAndClearLines()
        if cleared > 0 {
            score += cleared * 10 * combo
            combo += 1
            linesCleared += cleared
            SoundManager.shared.play(.clear)

            // Endless mode: ramp difficulty every 3 clears
            if config.isEndless, linesCleared % 3 == 0 {
                endlessJunkChance = min(0.5, endlessJunkChance + 0.05)
            }
        } else {
            combo = 1
        }
        updateHUD()

        // Check level completion before spawning
        if !config.isEndless && linesCleared >= config.linesToClear {
            endGame(completed: true)
            return
        }

        spawnAfterMove()
        checkBoardFull()
    }

    // MARK: - Line Clearing

    private func checkAndClearLines() -> Int {
        var rowsToClear: [(row: Int, color: BlockColor)] = []
        var colsToClear: [(col: Int, color: BlockColor)] = []

        for row in 0..<gridRows {
            if let color = uniformColorInRow(row) { rowsToClear.append((row, color)) }
        }
        for col in 0..<gridCols {
            if let color = uniformColorInCol(col) { colsToClear.append((col, color)) }
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

    private func uniformColorInRow(_ row: Int) -> BlockColor? {
        var found: BlockColor?
        for col in 0..<gridCols {
            switch board[row][col] {
            case .empty, .junk: return nil
            case .block(let c):
                if let f = found, f != c { return nil }
                found = c
            }
        }
        return found
    }

    private func uniformColorInCol(_ col: Int) -> BlockColor? {
        var found: BlockColor?
        for row in 0..<gridRows {
            switch board[row][col] {
            case .empty, .junk: return nil
            case .block(let c):
                if let f = found, f != c { return nil }
                found = c
            }
        }
        return found
    }

    private func animateClear(row: Int, col: Int, color: BlockColor) {
        let flash = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
        flash.position = positionFor(row: row, col: col)
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

    private func spawnAfterMove() {
        let junkChance = config.isEndless ? endlessJunkChance : config.junkSpawnChance
        let colorCount = config.isEndless ? endlessColorCount : config.colorCount

        var empties = emptyCells()
        guard let idx = empties.indices.randomElement() else { return }
        let (r, c) = empties[idx]
        board[r][c] = .block(BlockColor.random(from: colorCount))
        updateTile(row: r, col: c)
        animateSpawn(row: r, col: c)
        empties.remove(at: idx)

        if Double.random(in: 0...1) < junkChance, let jIdx = empties.indices.randomElement() {
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
        SoundManager.shared.play(.sweep)
        for col in 0..<gridCols {
            let flash = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
            flash.position = positionFor(row: row, col: col)
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
        linesCleared += 1
        refreshAllTiles()
        updateHUD()

        sweepSelecting = false
        sweepAvailable = false
        (sweepButton.children.first as? SKShapeNode)?.fillColor = SKColor(white: 0.3, alpha: 0.6)
        if let lbl = sweepButton.children.compactMap({ $0 as? SKLabelNode }).first {
            lbl.text = "USED"
            lbl.fontColor = SKColor(white: 0.5, alpha: 1)
        }

        if !config.isEndless && linesCleared >= config.linesToClear {
            endGame(completed: true)
        }
    }

    // MARK: - HUD

    private func updateHUD() {
        scoreLabel.text = "\(score)"
        comboLabel.text = "x\(combo)"
        if !config.isEndless {
            linesLabel?.text = "\(linesCleared)/\(config.linesToClear)"
        }
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

    // MARK: - Pause / Forfeit

    private func showPauseOverlay() {
        isShowingQuitPrompt = true

        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 80

        let bg = SKShapeNode(rectOf: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.1, alpha: 0.85)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let card = SKShapeNode(rectOf: CGSize(width: 260, height: 200), cornerRadius: 12)
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1)
        card.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 0.7)
        card.lineWidth = 2
        overlay.addChild(card)

        let title = makeLabel("QUIT GAME?", size: 22, color: SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1))
        title.position = CGPoint(x: 0, y: 50)
        title.zPosition = 81
        card.addChild(title)

        let sub = makeLabel("Progress will be lost", size: 14, color: SKColor(white: 0.5, alpha: 1))
        sub.position = CGPoint(x: 0, y: 20)
        sub.zPosition = 81
        card.addChild(sub)

        let quitBg = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 6)
        quitBg.position = CGPoint(x: -65, y: -30)
        quitBg.fillColor = SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1)
        quitBg.strokeColor = SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7)
        quitBg.lineWidth = 2
        quitBg.zPosition = 81
        quitBg.name = "quitConfirm"
        card.addChild(quitBg)
        let quitLabel = makeLabel("QUIT", size: 16, color: .white)
        quitLabel.verticalAlignmentMode = .center
        quitLabel.position = quitBg.position
        quitLabel.zPosition = 82
        quitLabel.name = "quitConfirm"
        card.addChild(quitLabel)

        let cancelBg = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 6)
        cancelBg.position = CGPoint(x: 65, y: -30)
        cancelBg.fillColor = SKColor(red: 0.2, green: 0.18, blue: 0.35, alpha: 1)
        cancelBg.strokeColor = SKColor(white: 0.4, alpha: 0.6)
        cancelBg.lineWidth = 2
        cancelBg.zPosition = 81
        cancelBg.name = "cancelQuit"
        card.addChild(cancelBg)
        let cancelLabel = makeLabel("CANCEL", size: 16, color: SKColor(white: 0.7, alpha: 1))
        cancelLabel.verticalAlignmentMode = .center
        cancelLabel.position = cancelBg.position
        cancelLabel.zPosition = 82
        cancelLabel.name = "cancelQuit"
        card.addChild(cancelLabel)

        addChild(overlay)
        pauseOverlay = overlay
    }

    private func dismissPauseOverlay() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
        isShowingQuitPrompt = false
    }

    private func goToMenu() {
        let menu = MenuScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: SKTransition.fade(withDuration: 0.4))
    }

    // MARK: - Game Over / Level Complete

    private func checkBoardFull() {
        if emptyCells().isEmpty { endGame(completed: false) }
    }

    private func endGame(completed: Bool) {
        guard !isGameOver else { return }
        isGameOver = true

        if completed {
            SoundManager.shared.play(.levelComplete)
            if !config.isEndless { LevelConfig.unlockNext(after: config.level) }
        } else {
            SoundManager.shared.play(.gameOver)
        }

        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(red: 0.05, green: 0.03, blue: 0.1, alpha: 0.85)
        overlay.strokeColor = .clear
        overlay.zPosition = 80
        addChild(overlay)

        let cardHeight: CGFloat = completed && !config.isEndless ? 300 : 280
        let card = SKShapeNode(rectOf: CGSize(width: 260, height: cardHeight), cornerRadius: 12)
        card.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        card.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.22, alpha: 1)
        card.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 0.7)
        card.lineWidth = 2
        card.zPosition = 85
        card.name = "endCard"
        addChild(card)

        let heading = completed ? "LEVEL CLEAR!" : "GAME OVER"
        let headingColor = completed
            ? SKColor(red: 0.35, green: 0.9, blue: 0.5, alpha: 1)
            : SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1)
        let headLabel = makeLabel(heading, size: 26, color: headingColor)
        headLabel.position = CGPoint(x: 0, y: 90)
        headLabel.zPosition = 86
        card.addChild(headLabel)

        let finalScore = makeLabel("SCORE: \(score)", size: 28, color: SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1))
        finalScore.position = CGPoint(x: 0, y: 40)
        finalScore.zPosition = 86
        card.addChild(finalScore)

        // Buttons
        var btnY: CGFloat = -10

        if completed && !config.isEndless && config.level < LevelConfig.levels.count {
            addEndButton(to: card, text: "NEXT LEVEL", name: "nextLevel", y: btnY,
                         fillColor: SKColor(red: 0.2, green: 0.7, blue: 0.35, alpha: 1),
                         strokeColor: SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 0.7))
            btnY -= 55
        }

        addEndButton(to: card, text: "RETRY", name: "retry", y: btnY,
                     fillColor: SKColor(red: 0.85, green: 0.25, blue: 0.3, alpha: 1),
                     strokeColor: SKColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 0.7))
        btnY -= 55

        addEndButton(to: card, text: "MENU", name: "menu", y: btnY,
                     fillColor: SKColor(red: 0.2, green: 0.18, blue: 0.35, alpha: 1),
                     strokeColor: SKColor(white: 0.4, alpha: 0.6))
    }

    private func addEndButton(to parent: SKNode, text: String, name: String, y: CGFloat,
                              fillColor: SKColor, strokeColor: SKColor) {
        let bg = SKShapeNode(rectOf: CGSize(width: 160, height: 44), cornerRadius: 6)
        bg.position = CGPoint(x: 0, y: y)
        bg.fillColor = fillColor
        bg.strokeColor = strokeColor
        bg.lineWidth = 2
        bg.zPosition = 86
        bg.name = name
        parent.addChild(bg)

        let label = makeLabel(text, size: 18, color: .white)
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: y)
        label.zPosition = 87
        label.name = name
        parent.addChild(label)
    }

    private func handleEndScreenTouch(_ tapped: [SKNode]) {
        if tapped.contains(where: { $0.name == "nextLevel" }) {
            let nextConfig = LevelConfig.forLevel(config.level + 1)
            let game = GameScene(size: size, config: nextConfig)
            game.scaleMode = scaleMode
            view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.4))
            return
        }
        if tapped.contains(where: { $0.name == "retry" }) {
            let game = GameScene(size: size, config: config)
            game.scaleMode = scaleMode
            view?.presentScene(game, transition: SKTransition.fade(withDuration: 0.4))
            return
        }
        if tapped.contains(where: { $0.name == "menu" }) {
            goToMenu()
        }
    }
}

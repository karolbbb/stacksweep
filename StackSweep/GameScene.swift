//
//  GameScene.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import SpriteKit

// MARK: - Cell State

/// Represents the state of each cell on the board.
enum CellState {
    case empty
    case block
    case junk
}

// MARK: - GameScene

class GameScene: SKScene {

    // MARK: - Grid Constants

    private let rows = 6
    private let columns = 6
    private let cellSize: CGFloat = 40
    private let cellGap: CGFloat = 4

    // MARK: - Board State

    /// 2D array representing the state of each cell on the board.
    private var board: [[CellState]] = []
    /// 2D array of tile nodes for visual representation; indices match board.
    private var tileNodes: [[SKSpriteNode]] = []
    /// Reference to the board container node for positioning.
    private var boardNode: SKNode?
    /// Starting X position of the board (left edge of first column).
    private var boardOriginX: CGFloat = 0
    /// Starting Y position of the board (bottom edge of first row).
    private var boardOriginY: CGFloat = 0

    // MARK: - Game State

    private var score = 0
    private var scoreLabel: SKLabelNode?
    private var sweepLabel: SKLabelNode?
    private var sweepUsed = false
    /// When true, the next tap selects a row to sweep.
    private var sweepModeActive = false
    private var gameOver = false

    // MARK: - Textures

    private var playerTexture: SKTexture?
    private var junkTexture: SKTexture?

    // MARK: - Setup

    override func didMove(to view: SKView) {
        // Load textures from the asset catalogue.
        playerTexture = SKTexture(imageNamed: "player")
        junkTexture = SKTexture(imageNamed: "junk")

        setupBackground()
        setupBoard()
        setupScoreLabel()
        setupSweepLabel()
    }

    /// Creates a full-screen background sprite using the retro arcade texture.
    private func setupBackground() {
        let backgroundTexture = SKTexture(imageNamed: "background")
        let background = SKSpriteNode(texture: backgroundTexture, size: size)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        addChild(background)
    }

    /// Initialises the board state array, computes board position, and creates tile nodes.
    private func setupBoard() {
        board = Array(repeating: Array(repeating: .empty, count: columns), count: rows)
        tileNodes = Array(repeating: Array(repeating: SKSpriteNode(), count: columns), count: rows)

        let totalWidth = CGFloat(columns) * cellSize + CGFloat(columns - 1) * cellGap
        let totalHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * cellGap
        boardOriginX = (size.width - totalWidth) / 2 + cellSize / 2
        boardOriginY = (size.height - totalHeight) / 2 + cellSize / 2

        let boardContainer = SKNode()
        boardContainer.position = .zero
        addChild(boardContainer)
        boardNode = boardContainer

        for row in 0..<rows {
            for col in 0..<columns {
                let tile = createTileNode(row: row, column: col)
                tileNodes[row][col] = tile
                boardContainer.addChild(tile)
            }
        }
    }

    /// Creates a single tile node with faint border; initially empty/clear.
    private func createTileNode(row: Int, column: Int) -> SKSpriteNode {
        let tile = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
        tile.position = positionForCell(row: row, column: column)
        tile.zPosition = 0
        tile.name = "tile"
        tile.userData = NSMutableDictionary(dictionary: ["row": row, "col": column])

        // Draw faint border so the grid is visible when cells are empty.
        let border = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
        border.strokeColor = SKColor(white: 0.3, alpha: 0.6)
        border.lineWidth = 1
        border.fillColor = .clear
        border.zPosition = 0.5
        tile.addChild(border)

        return tile
    }

    /// Returns the scene position for a given cell (row, column).
    private func positionForCell(row: Int, column: Int) -> CGPoint {
        let x = boardOriginX + CGFloat(column) * (cellSize + cellGap)
        let y = boardOriginY + CGFloat(row) * (cellSize + cellGap)
        return CGPoint(x: x, y: y)
    }

    /// Converts a scene position to board indices; returns nil if outside the grid.
    private func cellAt(position: CGPoint) -> (row: Int, column: Int)? {
        let colIdx = Int(round((position.x - boardOriginX) / (cellSize + cellGap)))
        let rowIdx = Int(round((position.y - boardOriginY) / (cellSize + cellGap)))
        if rowIdx >= 0, rowIdx < rows, colIdx >= 0, colIdx < columns {
            return (rowIdx, colIdx)
        }
        return nil
    }

    /// Returns the row index if the tap is within the board's row area; nil otherwise.
    private func rowAt(position: CGPoint) -> Int? {
        guard let (row, _) = cellAt(position: position) else { return nil }
        return row
    }

    private func setupScoreLabel() {
        let label = SKLabelNode(text: "0")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height - 60)
        label.zPosition = 10
        addChild(label)
        scoreLabel = label
    }

    private func setupSweepLabel() {
        let label = SKLabelNode(text: "Sweep")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = SKColor.cyan
        label.position = CGPoint(x: size.width / 2, y: 50)
        label.zPosition = 10
        addChild(label)
        sweepLabel = label
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Check if Sweep label was tapped.
        if let sweep = sweepLabel, !sweepUsed, !sweepModeActive {
            if sweep.contains(location) {
                activateSweepMode()
                return
            }
        }

        if sweepModeActive {
            handleSweepModeTap(at: location)
            return
        }

        // Normal gameplay: tap on a cell. Use node hit-test for reliable touch detection.
        if let (row, col) = cellFromTouch(at: location) {
            if board[row][col] == .empty {
                placeBlock(row: row, column: col)
            }
        }
    }

    /// Resolves tapped cell via node hit-test (more reliable than coordinate math).
    private func cellFromTouch(at location: CGPoint) -> (row: Int, column: Int)? {
        let nodesAtPoint = self.nodes(at: location)
        for node in nodesAtPoint {
            if node.name == "tile",
               let tile = node as? SKSpriteNode,
               let row = tile.userData?["row"] as? Int,
               let col = tile.userData?["col"] as? Int,
               row >= 0, row < rows, col >= 0, col < columns {
                return (row, col)
            }
        }
        return cellAt(position: location)
    }

    // MARK: - Game Logic

    /// Places a player block in the given cell, then checks for full lines and spawns junk.
    private func placeBlock(row: Int, column: Int) {
        board[row][column] = .block
        updateTileVisual(row: row, column: column)

        let linesCleared = checkAndClearLines(row: row, column: column)
        score += linesCleared
        scoreLabel?.text = "\(score)"

        spawnJunkBlock()
        checkGameOver()
    }

    /// Updates the tile's texture to match its state.
    private func updateTileVisual(row: Int, column: Int) {
        let tile = tileNodes[row][column]
        switch board[row][column] {
        case .empty:
            tile.texture = nil
            tile.color = .clear
        case .block:
            tile.texture = playerTexture
            tile.color = .clear
        case .junk:
            tile.texture = junkTexture
            tile.color = .clear
        }
    }

    /// Checks if the tapped row or column is full; if so, clears it and returns the number of lines cleared.
    private func checkAndClearLines(row: Int, column: Int) -> Int {
        var linesCleared = 0

        // Check row.
        var rowFull = true
        for c in 0..<columns {
            if board[row][c] == .empty {
                rowFull = false
                break
            }
        }
        if rowFull {
            for c in 0..<columns {
                board[row][c] = .empty
                updateTileVisual(row: row, column: c)
            }
            linesCleared += 1
        }

        // Check column.
        var colFull = true
        for r in 0..<rows {
            if board[r][column] == .empty {
                colFull = false
                break
            }
        }
        if colFull {
            for r in 0..<rows {
                board[r][column] = .empty
                updateTileVisual(row: r, column: column)
            }
            linesCleared += 1
        }

        return linesCleared
    }

    /// Randomly selects an empty cell and places a junk block there.
    private func spawnJunkBlock() {
        var emptyCells: [(Int, Int)] = []
        for r in 0..<rows {
            for c in 0..<columns {
                if board[r][c] == .empty {
                    emptyCells.append((r, c))
                }
            }
        }
        guard let (r, c) = emptyCells.randomElement() else { return }
        board[r][c] = .junk
        updateTileVisual(row: r, column: c)
    }

    // MARK: - Sweep Power

    private func activateSweepMode() {
        sweepModeActive = true
        sweepLabel?.text = "Select Row"
    }

    private func handleSweepModeTap(at position: CGPoint) {
        guard let row = rowAt(position: position) else { return }

        for c in 0..<columns {
            board[row][c] = .empty
            updateTileVisual(row: row, column: c)
        }
        score += 1
        scoreLabel?.text = "\(score)"

        sweepModeActive = false
        sweepUsed = true
        sweepLabel?.text = "Sweep used"
        sweepLabel?.fontColor = .gray

        checkGameOver()
    }

    // MARK: - Game Over

    private func checkGameOver() {
        for r in 0..<rows {
            for c in 0..<columns {
                if board[r][c] == .empty {
                    return
                }
            }
        }
        presentGameOver()
    }

    private func presentGameOver() {
        gameOver = true
        isUserInteractionEnabled = false

        let label = SKLabelNode(text: "Game over! Score: \(score)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 32
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 100
        addChild(label)
    }
}

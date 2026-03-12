//
//  ThemePack.swift
//  StackSweep
//

import SpriteKit

struct ThemePack {
    let id: String
    let name: String
    let price: Int
    let backgroundColor: SKColor
    let boardFill: SKColor
    let boardStroke: SKColor
    let emptyFill: SKColor
    let emptyStroke: SKColor
    let blockColors: [SKColor]
    let blockGlowAlpha: CGFloat
    let junkColor: SKColor
    let accentColor: SKColor
    let scanlineAlpha: CGFloat

    // MARK: - Catalog

    static let all: [ThemePack] = [
        .defaultTheme, .neonDreams, .retroWave, .goldenHour, .arctic
    ]

    static func current() -> ThemePack {
        let id = PlayerData.shared.equippedTheme
        return all.first { $0.id == id } ?? .defaultTheme
    }

    static func theme(for id: String) -> ThemePack {
        all.first { $0.id == id } ?? .defaultTheme
    }

    // MARK: - Themes

    static let defaultTheme = ThemePack(
        id: "default",
        name: "MIDNIGHT",
        price: 0,
        backgroundColor: SKColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1),
        boardFill: SKColor(red: 0.1, green: 0.08, blue: 0.18, alpha: 0.9),
        boardStroke: SKColor(red: 0.3, green: 0.25, blue: 0.5, alpha: 0.6),
        emptyFill: SKColor(white: 0.15, alpha: 0.2),
        emptyStroke: SKColor(white: 0.25, alpha: 0.4),
        blockColors: [
            SKColor(red: 0.95, green: 0.3, blue: 0.35, alpha: 1),
            SKColor(red: 0.3, green: 0.75, blue: 0.95, alpha: 1),
            SKColor(red: 0.35, green: 0.9, blue: 0.5, alpha: 1),
            SKColor(red: 0.95, green: 0.8, blue: 0.25, alpha: 1),
        ],
        blockGlowAlpha: 0.5,
        junkColor: SKColor(red: 0.28, green: 0.25, blue: 0.35, alpha: 1),
        accentColor: SKColor(red: 0.5, green: 0.4, blue: 0.8, alpha: 1),
        scanlineAlpha: 0.07
    )

    static let neonDreams = ThemePack(
        id: "neon",
        name: "NEON DREAMS",
        price: 200,
        backgroundColor: SKColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1),
        boardFill: SKColor(red: 0.04, green: 0.03, blue: 0.12, alpha: 0.95),
        boardStroke: SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 0.4),
        emptyFill: SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 0.3),
        emptyStroke: SKColor(red: 0.0, green: 0.5, blue: 0.7, alpha: 0.3),
        blockColors: [
            SKColor(red: 1.0, green: 0.1, blue: 0.5, alpha: 1),
            SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1),
            SKColor(red: 0.4, green: 1.0, blue: 0.2, alpha: 1),
            SKColor(red: 1.0, green: 0.95, blue: 0.0, alpha: 1),
        ],
        blockGlowAlpha: 0.7,
        junkColor: SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1),
        accentColor: SKColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1),
        scanlineAlpha: 0.12
    )

    static let retroWave = ThemePack(
        id: "retrowave",
        name: "RETRO WAVE",
        price: 200,
        backgroundColor: SKColor(red: 0.12, green: 0.02, blue: 0.15, alpha: 1),
        boardFill: SKColor(red: 0.15, green: 0.04, blue: 0.2, alpha: 0.9),
        boardStroke: SKColor(red: 0.9, green: 0.2, blue: 0.6, alpha: 0.5),
        emptyFill: SKColor(red: 0.2, green: 0.05, blue: 0.2, alpha: 0.25),
        emptyStroke: SKColor(red: 0.6, green: 0.1, blue: 0.4, alpha: 0.3),
        blockColors: [
            SKColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1),
            SKColor(red: 0.3, green: 0.4, blue: 1.0, alpha: 1),
            SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1),
            SKColor(red: 0.6, green: 0.1, blue: 1.0, alpha: 1),
        ],
        blockGlowAlpha: 0.6,
        junkColor: SKColor(red: 0.3, green: 0.1, blue: 0.3, alpha: 1),
        accentColor: SKColor(red: 1.0, green: 0.3, blue: 0.6, alpha: 1),
        scanlineAlpha: 0.1
    )

    static let goldenHour = ThemePack(
        id: "golden",
        name: "GOLDEN HOUR",
        price: 300,
        backgroundColor: SKColor(red: 0.12, green: 0.08, blue: 0.03, alpha: 1),
        boardFill: SKColor(red: 0.16, green: 0.12, blue: 0.05, alpha: 0.9),
        boardStroke: SKColor(red: 0.8, green: 0.65, blue: 0.2, alpha: 0.5),
        emptyFill: SKColor(red: 0.2, green: 0.15, blue: 0.06, alpha: 0.25),
        emptyStroke: SKColor(red: 0.5, green: 0.4, blue: 0.15, alpha: 0.35),
        blockColors: [
            SKColor(red: 1.0, green: 0.35, blue: 0.15, alpha: 1),
            SKColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1),
            SKColor(red: 0.85, green: 0.55, blue: 0.1, alpha: 1),
            SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1),
        ],
        blockGlowAlpha: 0.5,
        junkColor: SKColor(red: 0.3, green: 0.25, blue: 0.12, alpha: 1),
        accentColor: SKColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1),
        scanlineAlpha: 0.05
    )

    static let arctic = ThemePack(
        id: "arctic",
        name: "ARCTIC",
        price: 250,
        backgroundColor: SKColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1),
        boardFill: SKColor(red: 0.08, green: 0.12, blue: 0.2, alpha: 0.9),
        boardStroke: SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 0.4),
        emptyFill: SKColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 0.2),
        emptyStroke: SKColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.3),
        blockColors: [
            SKColor(red: 0.3, green: 0.75, blue: 1.0, alpha: 1),
            SKColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1),
            SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1),
            SKColor(red: 0.2, green: 0.5, blue: 0.85, alpha: 1),
        ],
        blockGlowAlpha: 0.6,
        junkColor: SKColor(red: 0.2, green: 0.25, blue: 0.35, alpha: 1),
        accentColor: SKColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1),
        scanlineAlpha: 0.06
    )
}

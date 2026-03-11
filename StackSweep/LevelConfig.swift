//
//  LevelConfig.swift
//  StackSweep
//
//  Created by Karol Bokszczanin on 11/03/2026.
//

import Foundation

struct LevelConfig {
    let level: Int              // 1-10 for fixed levels, 0 for endless
    let colorCount: Int
    let initialBlocks: Int
    let initialJunk: Int
    let junkSpawnChance: Double
    let roundDuration: TimeInterval
    let linesToClear: Int       // 0 means no target (endless)

    var isEndless: Bool { level == 0 }

    var displayName: String {
        isEndless ? "ENDLESS" : "LEVEL \(level)"
    }

    // MARK: - Fixed Levels

    static let levels: [LevelConfig] = [
        LevelConfig(level: 1,  colorCount: 2, initialBlocks: 4,  initialJunk: 0, junkSpawnChance: 0.0,  roundDuration: 120, linesToClear: 2),
        LevelConfig(level: 2,  colorCount: 2, initialBlocks: 6,  initialJunk: 0, junkSpawnChance: 0.0,  roundDuration: 120, linesToClear: 3),
        LevelConfig(level: 3,  colorCount: 3, initialBlocks: 6,  initialJunk: 1, junkSpawnChance: 0.10, roundDuration: 100, linesToClear: 4),
        LevelConfig(level: 4,  colorCount: 3, initialBlocks: 8,  initialJunk: 1, junkSpawnChance: 0.10, roundDuration: 100, linesToClear: 5),
        LevelConfig(level: 5,  colorCount: 3, initialBlocks: 8,  initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 6),
        LevelConfig(level: 6,  colorCount: 3, initialBlocks: 9,  initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 7),
        LevelConfig(level: 7,  colorCount: 3, initialBlocks: 10, initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 8),
        LevelConfig(level: 8,  colorCount: 4, initialBlocks: 10, initialJunk: 3, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 9),
        LevelConfig(level: 9,  colorCount: 4, initialBlocks: 11, initialJunk: 3, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 10),
        LevelConfig(level: 10, colorCount: 4, initialBlocks: 12, initialJunk: 4, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 12),
    ]

    static let endless = LevelConfig(
        level: 0, colorCount: 4, initialBlocks: 8, initialJunk: 2,
        junkSpawnChance: 0.20, roundDuration: 90, linesToClear: 0
    )

    static func forLevel(_ n: Int) -> LevelConfig {
        guard n >= 1, n <= levels.count else { return endless }
        return levels[n - 1]
    }

    // MARK: - Persistence

    private static let unlockedKey = "maxUnlockedLevel"

    static var maxUnlockedLevel: Int {
        get { max(UserDefaults.standard.integer(forKey: unlockedKey), 1) }
        set { UserDefaults.standard.set(newValue, forKey: unlockedKey) }
    }

    static func unlockNext(after level: Int) {
        let next = level + 1
        if next > maxUnlockedLevel, next <= levels.count {
            maxUnlockedLevel = next
        }
    }
}

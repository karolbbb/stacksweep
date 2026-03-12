//
//  LevelConfig.swift
//  StackSweep
//

import Foundation

struct LevelConfig {
    let level: Int
    let colorCount: Int
    let initialBlocks: Int
    let initialJunk: Int
    let junkSpawnChance: Double
    let roundDuration: TimeInterval
    let linesToClear: Int
    let twoStarScore: Int
    let threeStarScore: Int

    var isEndless: Bool { level == 0 }

    var displayName: String {
        isEndless ? "ENDLESS" : "LEVEL \(level)"
    }

    func starsFor(score: Int) -> Int {
        if isEndless { return 0 }
        if score >= threeStarScore { return 3 }
        if score >= twoStarScore { return 2 }
        return 1
    }

    // MARK: - Fixed Levels

    static let levels: [LevelConfig] = [
        LevelConfig(level: 1,  colorCount: 2, initialBlocks: 4,  initialJunk: 0, junkSpawnChance: 0.0,  roundDuration: 120, linesToClear: 2,  twoStarScore: 40,  threeStarScore: 80),
        LevelConfig(level: 2,  colorCount: 2, initialBlocks: 6,  initialJunk: 0, junkSpawnChance: 0.0,  roundDuration: 120, linesToClear: 3,  twoStarScore: 70,  threeStarScore: 140),
        LevelConfig(level: 3,  colorCount: 3, initialBlocks: 6,  initialJunk: 1, junkSpawnChance: 0.10, roundDuration: 100, linesToClear: 4,  twoStarScore: 100, threeStarScore: 200),
        LevelConfig(level: 4,  colorCount: 3, initialBlocks: 8,  initialJunk: 1, junkSpawnChance: 0.10, roundDuration: 100, linesToClear: 5,  twoStarScore: 140, threeStarScore: 280),
        LevelConfig(level: 5,  colorCount: 3, initialBlocks: 8,  initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 6,  twoStarScore: 180, threeStarScore: 360),
        LevelConfig(level: 6,  colorCount: 3, initialBlocks: 9,  initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 7,  twoStarScore: 220, threeStarScore: 440),
        LevelConfig(level: 7,  colorCount: 3, initialBlocks: 10, initialJunk: 2, junkSpawnChance: 0.20, roundDuration: 90,  linesToClear: 8,  twoStarScore: 260, threeStarScore: 520),
        LevelConfig(level: 8,  colorCount: 4, initialBlocks: 10, initialJunk: 3, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 9,  twoStarScore: 300, threeStarScore: 600),
        LevelConfig(level: 9,  colorCount: 4, initialBlocks: 11, initialJunk: 3, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 10, twoStarScore: 350, threeStarScore: 700),
        LevelConfig(level: 10, colorCount: 4, initialBlocks: 12, initialJunk: 4, junkSpawnChance: 0.30, roundDuration: 75,  linesToClear: 12, twoStarScore: 420, threeStarScore: 840),
    ]

    static let endless = LevelConfig(
        level: 0, colorCount: 4, initialBlocks: 8, initialJunk: 2,
        junkSpawnChance: 0.20, roundDuration: 90, linesToClear: 0,
        twoStarScore: 0, threeStarScore: 0
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

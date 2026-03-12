//
//  PlayerData.swift
//  StackSweep
//

import Foundation

final class PlayerData {

    static let shared = PlayerData()

    private let defaults = UserDefaults.standard

    // MARK: - Coins

    var coins: Int {
        get { defaults.integer(forKey: "pd_coins") }
        set { defaults.set(newValue, forKey: "pd_coins") }
    }

    func addCoins(_ amount: Int) {
        coins += amount
    }

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    // MARK: - Power-Up Inventory

    func powerUpCount(for type: String) -> Int {
        defaults.integer(forKey: "pd_pu_\(type)")
    }

    func addPowerUp(_ type: String, count: Int = 1) {
        let current = powerUpCount(for: type)
        defaults.set(current + count, forKey: "pd_pu_\(type)")
    }

    func consumePowerUp(_ type: String) -> Bool {
        let current = powerUpCount(for: type)
        guard current > 0 else { return false }
        defaults.set(current - 1, forKey: "pd_pu_\(type)")
        return true
    }

    // MARK: - Themes

    var ownedThemes: Set<String> {
        get { Set(defaults.stringArray(forKey: "pd_ownedThemes") ?? ["default"]) }
        set { defaults.set(Array(newValue), forKey: "pd_ownedThemes") }
    }

    var equippedTheme: String {
        get { defaults.string(forKey: "pd_equippedTheme") ?? "default" }
        set { defaults.set(newValue, forKey: "pd_equippedTheme") }
    }

    func unlockTheme(_ id: String) {
        var owned = ownedThemes
        owned.insert(id)
        ownedThemes = owned
    }

    // MARK: - Daily Streak

    var currentStreak: Int {
        get { defaults.integer(forKey: "pd_streak") }
        set { defaults.set(newValue, forKey: "pd_streak") }
    }

    var lastPlayDate: Date? {
        get { defaults.object(forKey: "pd_lastPlay") as? Date }
        set { defaults.set(newValue, forKey: "pd_lastPlay") }
    }

    var hasClaimedToday: Bool {
        get { defaults.bool(forKey: "pd_claimedToday") }
        set { defaults.set(newValue, forKey: "pd_claimedToday") }
    }

    /// Returns (isNewDay, coinsAwarded). Call once on app launch / menu appear.
    func checkDailyStreak() -> (isNewDay: Bool, reward: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastPlayDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                return (false, 0)
            }
            let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastPlayDate = today
        hasClaimedToday = false

        let reward = streakReward(for: currentStreak)
        return (true, reward)
    }

    func claimDailyReward() -> Int {
        guard !hasClaimedToday else { return 0 }
        hasClaimedToday = true
        let reward = streakReward(for: currentStreak)
        addCoins(reward)
        return reward
    }

    private func streakReward(for day: Int) -> Int {
        let capped = min(day, 7)
        return [0, 10, 15, 20, 30, 40, 50, 100][capped]
    }

    // MARK: - Stats

    var totalLinesCleared: Int {
        get { defaults.integer(forKey: "pd_totalLines") }
        set { defaults.set(newValue, forKey: "pd_totalLines") }
    }

    var highestCombo: Int {
        get { defaults.integer(forKey: "pd_highCombo") }
        set { defaults.set(newValue, forKey: "pd_highCombo") }
    }

    var totalGamesPlayed: Int {
        get { defaults.integer(forKey: "pd_gamesPlayed") }
        set { defaults.set(newValue, forKey: "pd_gamesPlayed") }
    }

    var totalCoinsEarned: Int {
        get { defaults.integer(forKey: "pd_totalCoins") }
        set { defaults.set(newValue, forKey: "pd_totalCoins") }
    }

    func bestScore(for level: Int) -> Int {
        defaults.integer(forKey: "pd_best_\(level)")
    }

    func updateBestScore(_ score: Int, for level: Int) {
        if score > bestScore(for: level) {
            defaults.set(score, forKey: "pd_best_\(level)")
        }
    }

    func starRating(for level: Int) -> Int {
        defaults.integer(forKey: "pd_stars_\(level)")
    }

    func updateStarRating(_ stars: Int, for level: Int) {
        if stars > starRating(for: level) {
            defaults.set(stars, forKey: "pd_stars_\(level)")
        }
    }

    var endlessHighScore: Int {
        get { defaults.integer(forKey: "pd_endlessHigh") }
        set { if newValue > defaults.integer(forKey: "pd_endlessHigh") { defaults.set(newValue, forKey: "pd_endlessHigh") } }
    }

    func recordGameEnd(score: Int, lines: Int, combo: Int, level: Int) {
        totalGamesPlayed += 1
        totalLinesCleared += lines
        if combo > highestCombo { highestCombo = combo }
        updateBestScore(score, for: level)
        if level == 0 { endlessHighScore = score }
    }
}

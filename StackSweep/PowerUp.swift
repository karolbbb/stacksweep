//
//  PowerUp.swift
//  StackSweep
//

import SpriteKit

enum PowerUpType: String, CaseIterable {
    case bomb
    case colorBomb
    case freeze
    case shuffle

    var displayName: String {
        switch self {
        case .bomb:      return "BOMB"
        case .colorBomb: return "COLOR"
        case .freeze:    return "FREEZE"
        case .shuffle:   return "SHUFFLE"
        }
    }

    var icon: String {
        switch self {
        case .bomb:      return "💣"
        case .colorBomb: return "🌈"
        case .freeze:    return "❄️"
        case .shuffle:   return "🔀"
        }
    }

    var description: String {
        switch self {
        case .bomb:      return "Destroy a 3×3 area"
        case .colorBomb: return "Remove all of one color"
        case .freeze:    return "Pause timer 15s"
        case .shuffle:   return "Rearrange all blocks"
        }
    }

    var price: Int {
        switch self {
        case .bomb:      return 30
        case .colorBomb: return 40
        case .freeze:    return 20
        case .shuffle:   return 25
        }
    }

    var color: SKColor {
        switch self {
        case .bomb:      return SKColor(red: 0.95, green: 0.4, blue: 0.2, alpha: 1)
        case .colorBomb: return SKColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1)
        case .freeze:    return SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
        case .shuffle:   return SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1)
        }
    }

    var targetingPrompt: String {
        switch self {
        case .bomb:      return "TAP TARGET"
        case .colorBomb: return "TAP COLOR"
        case .freeze:    return ""
        case .shuffle:   return ""
        }
    }

    var needsTarget: Bool {
        switch self {
        case .bomb, .colorBomb: return true
        case .freeze, .shuffle: return false
        }
    }
}

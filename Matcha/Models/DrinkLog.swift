// DrinkLog.swift
// Matcha

import Foundation
import SwiftData

@Model
final class DrinkLog {
    @Attribute(.unique) var id: UUID
    var name: String
    var calories: Int
    var caffeineMg: Int
    var category: String
    var emoji: String
    var loggedAt: Date
    
    /// The sticker rewarded for this drink (if any)
    var rewardedStickerID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        caffeineMg: Int,
        category: String,
        emoji: String,
        loggedAt: Date = Date(),
        rewardedStickerID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.caffeineMg = caffeineMg
        self.category = category
        self.emoji = emoji
        self.loggedAt = loggedAt
        self.rewardedStickerID = rewardedStickerID
    }
}

// Sticker.swift
// Matcha

import Foundation
import SwiftData

enum StickerRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case legendary
    
    var displayName: String {
        rawValue.capitalized
    }
    
    /// Weight for gacha probability (higher = more common)
    var weight: Int {
        switch self {
        case .common: 60
        case .uncommon: 25
        case .rare: 12
        case .legendary: 3
        }
    }
}

@Model
final class Sticker {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String          // "Tea", "Coffee", "Sweet", "Water"
    var rarityRaw: String         // Store as String for SwiftData compatibility
    var imageName: String         // SF Symbol or asset name
    var ownedCount: Int           // 0 = locked, 1+ = owned
    var unlockedAt: Date?
    
    var rarity: StickerRarity {
        get { StickerRarity(rawValue: rarityRaw) ?? .common }
        set { rarityRaw = newValue.rawValue }
    }
    
    var isUnlocked: Bool { ownedCount > 0 }
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        rarity: StickerRarity,
        imageName: String,
        ownedCount: Int = 0,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.rarityRaw = rarity.rawValue
        self.imageName = imageName
        self.ownedCount = ownedCount
        self.unlockedAt = unlockedAt
    }
}

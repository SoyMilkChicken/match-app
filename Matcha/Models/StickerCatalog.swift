// StickerCatalog.swift
// Matcha

import Foundation

/// All possible stickers in the game - seeded on first launch
enum StickerCatalog {
    static let all: [(name: String, category: String, rarity: StickerRarity, imageName: String)] = [
        // Tea category
        ("Green Tea Leaf", "Tea", .common, "leaf.fill"),
        ("Matcha Whisk", "Tea", .uncommon, "wand.and.stars"),
        ("Teapot Spirit", "Tea", .rare, "theatermasks.fill"),
        ("Zen Master", "Tea", .legendary, "sparkles"),
        
        // Coffee category
        ("Coffee Bean", "Coffee", .common, "oval.fill"),
        ("Espresso Shot", "Coffee", .uncommon, "bolt.fill"),
        ("Latte Art", "Coffee", .rare, "heart.fill"),
        ("Barista Badge", "Coffee", .legendary, "star.fill"),
        
        // Sweet category
        ("Boba Pearl", "Sweet", .common, "circle.fill"),
        ("Tapioca Tower", "Sweet", .uncommon, "triangle.fill"),
        ("Sugar Rush", "Sweet", .rare, "flame.fill"),
        ("Golden Boba", "Sweet", .legendary, "crown.fill"),
        
        // Water category
        ("Water Drop", "Water", .common, "drop.fill"),
        ("Crystal Stream", "Water", .uncommon, "wind"),
        ("Ocean Wave", "Water", .rare, "water.waves"),
        ("Hydration Hero", "Water", .legendary, "trophy.fill"),
    ]
    
    /// Create Sticker models from catalog (ownedCount = 0)
    static func seedStickers() -> [Sticker] {
        all.map { item in
            Sticker(
                name: item.name,
                category: item.category,
                rarity: item.rarity,
                imageName: item.imageName,
                ownedCount: 0
            )
        }
    }
}

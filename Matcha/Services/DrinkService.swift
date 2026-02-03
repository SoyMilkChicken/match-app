// DrinkService.swift
// Matcha

import Foundation
import SwiftData

@MainActor
final class DrinkService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Log a drink from preset and trigger sticker reward
    func logDrink(preset: DrinkPreset) throws -> Sticker? {
        return try logDrink(
            name: preset.name,
            calories: preset.calories,
            caffeineMg: preset.caffeineMg,
            category: preset.category,
            emoji: preset.emoji
        )
    }
    
    /// Log a drink from CustomDrink and trigger sticker reward
    func logDrink(drink: CustomDrink) throws -> Sticker? {
        return try logDrink(
            name: drink.name,
            calories: drink.calories,
            caffeineMg: drink.caffeineMg,
            category: drink.category,
            emoji: drink.emoji
        )
    }
    
    /// Core logging implementation
    private func logDrink(name: String, calories: Int, caffeineMg: Int, category: String, emoji: String) throws -> Sticker? {
        // Create drink log
        let log = DrinkLog(
            name: name,
            calories: calories,
            caffeineMg: caffeineMg,
            category: category,
            emoji: emoji
        )
        modelContext.insert(log)
        
        // Update user stats
        let stats = try getOrCreateUserStats()
        stats.totalDrinksLogged += 1
        stats.totalCalories += calories
        stats.totalCaffeineMg += caffeineMg
        stats.lastDrinkAt = Date()
        
        // Roll for sticker
        let sticker = try rollSticker(for: category)
        log.rewardedStickerID = sticker.id
        
        try modelContext.save()
        return sticker
    }
    
    /// Get today's totals
    func todayTotals() throws -> (calories: Int, caffeine: Int, drinks: Int) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<DrinkLog>(
            predicate: #Predicate { $0.loggedAt >= startOfDay }
        )
        
        let logs = try modelContext.fetch(descriptor)
        
        let calories = logs.reduce(0) { $0 + $1.calories }
        let caffeine = logs.reduce(0) { $0 + $1.caffeineMg }
        
        return (calories, caffeine, logs.count)
    }
    
    /// Get or create user stats singleton
    func getOrCreateUserStats() throws -> UserStats {
        let descriptor = FetchDescriptor<UserStats>()
        let existing = try modelContext.fetch(descriptor)
        
        if let stats = existing.first {
            return stats
        }
        
        let stats = UserStats()
        modelContext.insert(stats)
        return stats
    }
    
    /// Roll a sticker based on category with weighted rarity
    private func rollSticker(for category: String) throws -> Sticker {
        // Fetch all stickers in this category
        let descriptor = FetchDescriptor<Sticker>(
            predicate: #Predicate { $0.category == category }
        )
        let stickers = try modelContext.fetch(descriptor)
        
        guard !stickers.isEmpty else {
            // Fallback: grab any sticker
            let fallback = FetchDescriptor<Sticker>()
            let all = try modelContext.fetch(fallback)
            return all.randomElement()!
        }
        
        // Weighted random selection
        let totalWeight = stickers.reduce(0) { $0 + $1.rarity.weight }
        var roll = Int.random(in: 0..<totalWeight)
        
        for sticker in stickers {
            roll -= sticker.rarity.weight
            if roll < 0 {
                // Winner!
                sticker.ownedCount += 1
                if sticker.unlockedAt == nil {
                    sticker.unlockedAt = Date()
                }
                return sticker
            }
        }
        
        // Fallback (shouldn't reach here)
        let winner = stickers.first!
        winner.ownedCount += 1
        return winner
    }
}

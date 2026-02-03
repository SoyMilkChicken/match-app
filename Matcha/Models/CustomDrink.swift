// CustomDrink.swift
// Matcha

import Foundation
import SwiftData

@Model
final class CustomDrink {
    @Attribute(.unique) var id: UUID
    var name: String
    var calories: Int
    var caffeineMg: Int
    var category: String
    var emoji: String
    var isDefault: Bool  // true = seeded preset, false = user-created
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        caffeineMg: Int,
        category: String,
        emoji: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.caffeineMg = caffeineMg
        self.category = category
        self.emoji = emoji
        self.isDefault = isDefault
    }
}

// MARK: - Default Presets

extension CustomDrink {
    static func defaultPresets() -> [CustomDrink] {
        [
            CustomDrink(name: "Matcha Latte", calories: 120, caffeineMg: 70, category: "Tea", emoji: "🍵", isDefault: true),
            CustomDrink(name: "Boba Tea", calories: 350, caffeineMg: 50, category: "Sweet", emoji: "🧋", isDefault: true),
            CustomDrink(name: "Black Coffee", calories: 5, caffeineMg: 95, category: "Coffee", emoji: "☕️", isDefault: true),
            CustomDrink(name: "Espresso", calories: 10, caffeineMg: 63, category: "Coffee", emoji: "🫖", isDefault: true),
            CustomDrink(name: "Water", calories: 0, caffeineMg: 0, category: "Water", emoji: "💧", isDefault: true),
            CustomDrink(name: "Chai Latte", calories: 190, caffeineMg: 50, category: "Tea", emoji: "🫖", isDefault: true),
        ]
    }
}

// MARK: - Drink Categories

enum DrinkCategory: String, CaseIterable, Identifiable {
    case tea = "Tea"
    case coffee = "Coffee"
    case sweet = "Sweet"
    case water = "Water"
    
    var id: String { rawValue }
}

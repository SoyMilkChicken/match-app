// DrinkPreset.swift
// Matcha

import Foundation

struct DrinkPreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let calories: Int
    let caffeineMg: Int
    let category: String
    let emoji: String
    
    static let all: [DrinkPreset] = [
        DrinkPreset(name: "Matcha Latte", calories: 120, caffeineMg: 70, category: "Tea", emoji: "🍵"),
        DrinkPreset(name: "Boba Tea", calories: 350, caffeineMg: 50, category: "Sweet", emoji: "🧋"),
        DrinkPreset(name: "Black Coffee", calories: 5, caffeineMg: 95, category: "Coffee", emoji: "☕️"),
        DrinkPreset(name: "Espresso", calories: 10, caffeineMg: 63, category: "Coffee", emoji: "🫖"),
        DrinkPreset(name: "Water", calories: 0, caffeineMg: 0, category: "Water", emoji: "💧"),
        DrinkPreset(name: "Chai Latte", calories: 190, caffeineMg: 50, category: "Tea", emoji: "🫖"),
    ]
}

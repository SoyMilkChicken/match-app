// UserStats.swift
// Matcha

import Foundation
import SwiftData

@Model
final class UserStats {
    @Attribute(.unique) var id: UUID
    var totalDrinksLogged: Int
    var totalCalories: Int
    var totalCaffeineMg: Int
    var lastDrinkAt: Date?
    
    init(
        id: UUID = UUID(),
        totalDrinksLogged: Int = 0,
        totalCalories: Int = 0,
        totalCaffeineMg: Int = 0,
        lastDrinkAt: Date? = nil
    ) {
        self.id = id
        self.totalDrinksLogged = totalDrinksLogged
        self.totalCalories = totalCalories
        self.totalCaffeineMg = totalCaffeineMg
        self.lastDrinkAt = lastDrinkAt
    }
}

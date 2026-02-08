// Color+Extension.swift
// Matcha

import SwiftUI

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Green Serenity Palette
    
    /// #88B04B - Fresh Matcha Powder Green (Main brand color, buttons, active tabs)
    static let matchaPrimary = Color(hex: "#88B04B")
    
    /// #F9FBE7 - Light Lemon Cream tint (App background, readable surface)
    static let matchaSurface = Color(hex: "#F9FBE7")
    
    /// #1f1f1f - Ink Black (Primary text, headlines, icons)
    static let matchaForest = Color(hex: "#1f1f1f")
    
    /// #7aa520 - Fresh Lime (Secondary text, inactive states, borders)
    static let matchaSage = Color(hex: "#7aa520")
    
    /// #cddd77 - Lemon Cream (Success states, sticker glows, highlights)
    static let matchaSuccess = Color(hex: "#cddd77")
    
    /// #cddd77 - Lemon Cream (Decorative cards, backgrounds behind dark text)
    static let matchaAccent = Color(hex: "#cddd77")
}

// PlacedSticker.swift
// Matcha

import Foundation
import SwiftData

@Model
final class PlacedSticker {
    @Attribute(.unique) var id: UUID
    var stickerID: UUID   // Reference to Sticker.id
    var x: Double
    var y: Double
    var rotation: Double  // Radians
    var scale: Double
    
    init(
        id: UUID = UUID(),
        stickerID: UUID,
        x: Double,
        y: Double,
        rotation: Double = 0,
        scale: Double = 1.0
    ) {
        self.id = id
        self.stickerID = stickerID
        self.x = x
        self.y = y
        self.rotation = rotation
        self.scale = scale
    }
}

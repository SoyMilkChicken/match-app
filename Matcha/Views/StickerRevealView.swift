// StickerRevealView.swift
// Matcha

import SwiftUI

struct StickerRevealView: View {
    let sticker: Sticker
    @Environment(\.dismiss) private var dismiss
    
    @State private var isRevealed = false
    @State private var rotation: Double = 0
    
    private var rarityColor: Color {
        switch sticker.rarity {
        case .common: .matchaSage
        case .uncommon: .matchaPrimary
        case .rare: .blue
        case .legendary: .orange
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.matchaSurface
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Spinning reveal animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [rarityColor.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(isRevealed ? 1.2 : 0.8)
                    
                    // Sticker icon
                    Image(systemName: sticker.imageName)
                        .font(.system(size: 80))
                        .foregroundStyle(rarityColor)
                        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                        .scaleEffect(isRevealed ? 1 : 0.5)
                        .opacity(isRevealed ? 1 : 0)
                }
                .frame(height: 200)
                
                // Sticker info
                VStack(spacing: 8) {
                    Text(sticker.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.matchaForest)
                    
                    Text(sticker.rarity.displayName.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(rarityColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(rarityColor.opacity(0.15))
                        .clipShape(Capsule())
                    
                    if sticker.ownedCount > 1 {
                        Text("Duplicate #\(sticker.ownedCount)")
                            .font(.caption)
                            .foregroundStyle(Color.matchaSage)
                    }
                }
                .opacity(isRevealed ? 1 : 0)
                
                Spacer()
                
                // Dismiss button
                Button {
                    dismiss()
                } label: {
                    Text("Awesome!")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.matchaPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .opacity(isRevealed ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                rotation = 720
                isRevealed = true
            }
        }
    }
}

#Preview {
    StickerRevealView(
        sticker: Sticker(
            name: "Green Tea Leaf",
            category: "Tea",
            rarity: .rare,
            imageName: "leaf.fill",
            ownedCount: 1,
            unlockedAt: Date()
        )
    )
}

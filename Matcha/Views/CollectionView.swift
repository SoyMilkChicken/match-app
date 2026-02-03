// CollectionView.swift
// Matcha

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \Sticker.name) private var allStickers: [Sticker]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var unlockedCount: Int {
        allStickers.filter { $0.isUnlocked }.count
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress bar
                    progressHeader
                    
                    // Sticker grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(allStickers) { sticker in
                            StickerCell(sticker: sticker)
                        }
                    }
                }
                .padding()
            }
            .background(Color.matchaSurface)
            .navigationTitle("Collection")
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Collected")
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaForest)
                Spacer()
                Text("\(unlockedCount) / \(allStickers.count)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.matchaPrimary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.matchaSage.opacity(0.3))
                    
                    Capsule()
                        .fill(Color.matchaPrimary)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
    
    private var progress: Double {
        guard !allStickers.isEmpty else { return 0 }
        return Double(unlockedCount) / Double(allStickers.count)
    }
}

struct StickerCell: View {
    let sticker: Sticker
    
    private var rarityColor: Color {
        switch sticker.rarity {
        case .common: .matchaSage
        case .uncommon: .matchaPrimary
        case .rare: .blue
        case .legendary: .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(sticker.isUnlocked ? .white : Color.matchaSage.opacity(0.2))
                    .shadow(color: sticker.isUnlocked ? rarityColor.opacity(0.3) : .clear, radius: 8)
                
                if sticker.isUnlocked {
                    Image(systemName: sticker.imageName)
                        .font(.system(size: 36))
                        .foregroundStyle(rarityColor)
                } else {
                    // Silhouette
                    Image(systemName: sticker.imageName)
                        .font(.system(size: 36))
                        .foregroundStyle(Color.matchaSage.opacity(0.3))
                }
                
                // Duplicate badge
                if sticker.ownedCount > 1 {
                    Text("×\(sticker.ownedCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.matchaPrimary)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(6)
                }
            }
            .frame(height: 90)
            
            Text(sticker.isUnlocked ? sticker.name : "???")
                .font(.caption2)
                .foregroundStyle(sticker.isUnlocked ? Color.matchaForest : Color.matchaSage)
                .lineLimit(1)
        }
    }
}

#Preview {
    CollectionView()
        .modelContainer(for: Sticker.self, inMemory: true)
}

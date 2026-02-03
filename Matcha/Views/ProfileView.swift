// ProfileView.swift
// Matcha

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var stats: [UserStats]
    @Query(filter: #Predicate<Sticker> { $0.ownedCount > 0 }) private var unlockedStickers: [Sticker]
    
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showTrading = false
    
    private var userStats: UserStats? {
        stats.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar area
                    avatarSection
                    
                    // Stats cards
                    statsSection
                    
                    // Action buttons
                    tradeButton
                    shareButton
                }
                .padding()
            }
            .background(Color.matchaSurface)
            .navigationTitle("Profile")
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(image: image)
                }
            }
            .fullScreenCover(isPresented: $showTrading) {
                TradingView()
            }
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.matchaPrimary, .matchaSuccess],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            
            Text("Matcha Collector")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.matchaForest)
            
            Text("\(unlockedStickers.count) stickers collected")
                .font(.subheadline)
                .foregroundStyle(Color.matchaSage)
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ProfileStatCard(
                    title: "Total Drinks",
                    value: "\(userStats?.totalDrinksLogged ?? 0)",
                    icon: "cup.and.saucer.fill"
                )
                ProfileStatCard(
                    title: "Total Caffeine",
                    value: "\(userStats?.totalCaffeineMg ?? 0) mg",
                    icon: "bolt.fill"
                )
            }
            
            HStack(spacing: 16) {
                ProfileStatCard(
                    title: "Total Calories",
                    value: "\(userStats?.totalCalories ?? 0)",
                    icon: "flame.fill"
                )
                ProfileStatCard(
                    title: "Rare+ Stickers",
                    value: "\(rareOrBetterCount)",
                    icon: "sparkles"
                )
            }
        }
    }
    
    private var rareOrBetterCount: Int {
        unlockedStickers.filter { $0.rarity == .rare || $0.rarity == .legendary }.count
    }
    
    private var tradeButton: some View {
        Button {
            showTrading = true
        } label: {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Trade Stickers")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.matchaSuccess)
            .foregroundStyle(Color.matchaForest)
            .clipShape(Capsule())
        }
    }
    
    private var shareButton: some View {
        Button {
            generateShareCard()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Collection")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.matchaPrimary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
    }
    
    @MainActor
    private func generateShareCard() {
        let card = ShareCardView(
            stickerCount: unlockedStickers.count,
            totalDrinks: userStats?.totalDrinksLogged ?? 0,
            rareSticker: unlockedStickers.first { $0.rarity == .legendary || $0.rarity == .rare }
        )
        
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.matchaPrimary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.matchaForest)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.matchaSage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
}

// MARK: - Share Card

struct ShareCardView: View {
    let stickerCount: Int
    let totalDrinks: Int
    let rareSticker: Sticker?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.title)
                Text("Matcha")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.matchaPrimary)
            
            // Featured sticker
            if let sticker = rareSticker {
                VStack(spacing: 8) {
                    Image(systemName: sticker.imageName)
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text(sticker.name)
                        .font(.headline)
                        .foregroundStyle(Color.matchaForest)
                    
                    Text(sticker.rarity.displayName.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }
            
            // Stats
            HStack(spacing: 32) {
                VStack {
                    Text("\(stickerCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Stickers")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(totalDrinks)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Drinks")
                        .font(.caption)
                }
            }
            .foregroundStyle(Color.matchaForest)
        }
        .padding(32)
        .frame(width: 300, height: 500)
        .background(Color.matchaSurface)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserStats.self, Sticker.self], inMemory: true)
}

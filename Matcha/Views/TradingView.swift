// TradingView.swift
// Matcha

import SwiftUI
import SwiftData

struct TradingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Sticker> { $0.ownedCount > 1 }) private var tradableStickers: [Sticker]
    @Query private var allStickers: [Sticker]
    
    @State private var tradingManager = TradingManager()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.matchaSurface
                    .ignoresSafeArea()
                
                content
            }
            .navigationTitle("Trade Stickers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        tradingManager.stopSearching()
                        dismiss()
                    }
                    .foregroundStyle(Color.matchaForest)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupCallbacks()
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch tradingManager.state {
        case .idle:
            idleView
        case .searching:
            searchingView
        case .connected(let peerName):
            connectedView(peerName: peerName)
        case .trading:
            tradingView
        }
    }
    
    // MARK: - Idle State
    
    private var idleView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(Color.matchaPrimary)
            
            Text("Trade Stickers")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.matchaForest)
            
            Text("Find nearby Matcha users and swap duplicate stickers!")
                .font(.subheadline)
                .foregroundStyle(Color.matchaSage)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                tradingManager.startSearching()
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Start Searching")
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.matchaPrimary)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Searching State
    
    private var searchingView: some View {
        VStack(spacing: 32) {
            // Radar animation
            RadarView()
                .frame(width: 200, height: 200)
            
            Text("Searching for traders...")
                .font(.headline)
                .foregroundStyle(Color.matchaForest)
            
            // Discovered peers
            if !tradingManager.discoveredPeers.isEmpty {
                VStack(spacing: 12) {
                    Text("Nearby Users")
                        .font(.subheadline)
                        .foregroundStyle(Color.matchaSage)
                    
                    ForEach(tradingManager.discoveredPeers, id: \.displayName) { peer in
                        Button {
                            tradingManager.invitePeer(peer)
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                Text(peer.displayName)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.matchaForest)
                    }
                }
                .padding(.horizontal)
            }
            
            Button("Cancel") {
                tradingManager.stopSearching()
            }
            .foregroundStyle(Color.matchaSage)
        }
    }
    
    // MARK: - Connected State
    
    private func connectedView(peerName: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.matchaSuccess)
            
            Text("Connected to")
                .font(.subheadline)
                .foregroundStyle(Color.matchaSage)
            
            Text(peerName)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.matchaForest)
            
            Text("Select a sticker to offer")
                .font(.subheadline)
                .foregroundStyle(Color.matchaSage)
            
            // Tradable stickers grid
            stickerSelectionGrid
            
            Button("Disconnect") {
                tradingManager.stopSearching()
            }
            .foregroundStyle(.red)
        }
        .padding()
    }
    
    // MARK: - Trading State
    
    private var tradingView: some View {
        VStack(spacing: 16) {
            Text("Trade in Progress")
                .font(.headline)
                .foregroundStyle(Color.matchaForest)
            
            HStack(spacing: 24) {
                // My offer
                VStack(spacing: 8) {
                    Text("Your Offer")
                        .font(.caption)
                        .foregroundStyle(Color.matchaSage)
                    
                    if let sticker = tradingManager.myOffer {
                        offerCard(name: sticker.name, imageName: sticker.imageName, rarity: sticker.rarity.rawValue)
                    }
                    
                    if tradingManager.iConfirmed {
                        Label("Confirmed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.matchaSuccess)
                    }
                }
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundStyle(Color.matchaSage)
                
                // Their offer
                VStack(spacing: 8) {
                    Text("Their Offer")
                        .font(.caption)
                        .foregroundStyle(Color.matchaSage)
                    
                    if let info = tradingManager.theirOffer {
                        offerCard(name: info.name, imageName: info.imageName, rarity: info.rarity)
                    }
                    
                    if tradingManager.theyConfirmed {
                        Label("Confirmed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.matchaSuccess)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                Button {
                    tradingManager.cancelTrade()
                } label: {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.matchaSage.opacity(0.3))
                        .foregroundStyle(Color.matchaForest)
                        .clipShape(Capsule())
                }
                
                Button {
                    tradingManager.confirmTrade()
                } label: {
                    Text(tradingManager.iConfirmed ? "Waiting..." : "Confirm Trade")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(tradingManager.iConfirmed ? Color.matchaSage : Color.matchaPrimary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(tradingManager.iConfirmed)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private var stickerSelectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tradableStickers) { sticker in
                    Button {
                        tradingManager.selectOffer(sticker)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: sticker.imageName)
                                .font(.system(size: 28))
                                .foregroundStyle(Color.matchaPrimary)
                            
                            Text(sticker.name)
                                .font(.caption2)
                                .foregroundStyle(Color.matchaForest)
                                .lineLimit(1)
                            
                            Text("×\(sticker.ownedCount)")
                                .font(.caption2)
                                .foregroundStyle(Color.matchaSage)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(color: Color.matchaForest.opacity(0.1), radius: 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 300)
    }
    
    private func offerCard(name: String, imageName: String, rarity: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: imageName)
                .font(.system(size: 40))
                .foregroundStyle(Color.matchaPrimary)
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.matchaForest)
                .multilineTextAlignment(.center)
            
            Text(rarity.capitalized)
                .font(.caption2)
                .foregroundStyle(Color.matchaSage)
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.matchaForest.opacity(0.1), radius: 8)
        )
    }
    
    private func setupCallbacks() {
        tradingManager.onError = { message in
            errorMessage = message
            showError = true
        }
        
        tradingManager.onTradeComplete = { receivedInfo in
            // Decrement my offer
            if let mySticker = tradingManager.myOffer {
                mySticker.ownedCount -= 1
            }
            
            // Increment or unlock received sticker
            if let received = allStickers.first(where: { $0.id == receivedInfo.id }) {
                received.ownedCount += 1
                if received.unlockedAt == nil {
                    received.unlockedAt = Date()
                }
            }
            
            try? modelContext.save()
        }
    }
}

// MARK: - Radar Animation

struct RadarView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Color.matchaPrimary.opacity(0.3), lineWidth: 2)
                    .scaleEffect(animate ? 1.5 : 0.5)
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.6),
                        value: animate
                    )
            }
            
            Circle()
                .fill(Color.matchaPrimary)
                .frame(width: 60, height: 60)
            
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    TradingView()
        .modelContainer(for: Sticker.self, inMemory: true)
}

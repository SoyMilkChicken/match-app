// ContentView.swift
// Matcha

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stickers: [Sticker]
    @Query private var drinks: [CustomDrink]
    
    var body: some View {
        TabView {
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "cup.and.saucer.fill")
                }
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2.fill")
                }
            
            StickerCanvasView()
                .tabItem {
                    Label("Canvas", systemImage: "paintpalette.fill")
                }
            
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "bubble.left.and.bubble.right.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.matchaPrimary)
        .task {
            // Seed stickers on first launch
            if stickers.isEmpty {
                for sticker in StickerCatalog.seedStickers() {
                    modelContext.insert(sticker)
                }
            }
            
            // Seed default drinks on first launch
            if drinks.isEmpty {
                for drink in CustomDrink.defaultPresets() {
                    modelContext.insert(drink)
                }
            }
            
            try? modelContext.save()
        }
    }
}

#Preview {
    ContentView()
}


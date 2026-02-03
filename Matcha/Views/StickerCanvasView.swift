// StickerCanvasView.swift
// Matcha

import SwiftUI
import SwiftData

struct StickerCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var placedStickers: [PlacedSticker]
    @Query(filter: #Predicate<Sticker> { $0.ownedCount > 0 }) private var unlockedStickers: [Sticker]
    
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var drawerHeight: CGFloat = 120
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Canvas background
                    canvasBackground
                        .frame(width: geo.size.width, height: geo.size.height - drawerHeight)
                    
                    // Placed stickers
                    ForEach(placedStickers) { placed in
                        PlacedStickerView(
                            placed: placed,
                            sticker: sticker(for: placed.stickerID),
                            onRemove: { removePlacedSticker(placed) }
                        )
                    }
                    
                    // Bottom drawer
                    VStack {
                        Spacer()
                        stickerDrawer
                            .frame(height: drawerHeight)
                    }
                }
            }
            .navigationTitle("Sticker Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        shareCanvas()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .secondaryAction) {
                    Button(role: .destructive) {
                        clearCanvas()
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(image: image)
                }
            }
        }
    }
    
    // MARK: - Canvas Background
    
    private var canvasBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [Color.matchaSurface, Color.matchaSage.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.matchaSage.opacity(0.5), lineWidth: 2)
            )
            .overlay(
                VStack {
                    Image(systemName: "laptopcomputer")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.matchaSage.opacity(0.3))
                    Text("Your Canvas")
                        .font(.caption)
                        .foregroundStyle(Color.matchaSage.opacity(0.5))
                }
                .opacity(placedStickers.isEmpty ? 1 : 0)
            )
            .padding()
    }
    
    // MARK: - Sticker Drawer
    
    private var stickerDrawer: some View {
        VStack(spacing: 8) {
            // Handle
            Capsule()
                .fill(Color.matchaSage.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(unlockedStickers) { sticker in
                        DrawerStickerView(sticker: sticker) {
                            addStickerToCanvas(sticker)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Helpers
    
    private func sticker(for id: UUID) -> Sticker? {
        unlockedStickers.first { $0.id == id }
    }
    
    private func addStickerToCanvas(_ sticker: Sticker) {
        let placed = PlacedSticker(
            stickerID: sticker.id,
            x: 150,
            y: 200,
            rotation: 0,
            scale: 1.0
        )
        modelContext.insert(placed)
        try? modelContext.save()
    }
    
    private func removePlacedSticker(_ placed: PlacedSticker) {
        modelContext.delete(placed)
        try? modelContext.save()
    }
    
    private func clearCanvas() {
        for placed in placedStickers {
            modelContext.delete(placed)
        }
        try? modelContext.save()
    }
    
    @MainActor
    private func shareCanvas() {
        let canvasContent = CanvasSnapshotView(
            placedStickers: placedStickers,
            allStickers: unlockedStickers
        )
        
        let renderer = ImageRenderer(content: canvasContent)
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }
}

// MARK: - Placed Sticker View (with gestures)

struct PlacedStickerView: View {
    @Bindable var placed: PlacedSticker
    let sticker: Sticker?
    let onRemove: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    
    var body: some View {
        if let sticker = sticker {
            Image(systemName: sticker.imageName)
                .font(.system(size: 50 * placed.scale * currentScale))
                .foregroundStyle(Color.matchaPrimary)
                .rotationEffect(.radians(placed.rotation) + currentRotation)
                .offset(
                    x: placed.x + dragOffset.width,
                    y: placed.y + dragOffset.height
                )
                .gesture(dragGesture)
                .gesture(magnificationGesture)
                .gesture(rotationGesture)
                .onTapGesture(count: 2) {
                    onRemove()
                }
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                placed.x += value.translation.width
                placed.y += value.translation.height
                dragOffset = .zero
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentScale = value
            }
            .onEnded { value in
                placed.scale *= value
                currentScale = 1.0
            }
    }
    
    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                currentRotation = value
            }
            .onEnded { value in
                placed.rotation += value.radians
                currentRotation = .zero
            }
    }
}

// MARK: - Drawer Sticker View

struct DrawerStickerView: View {
    let sticker: Sticker
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: sticker.imageName)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.matchaPrimary)
                
                Text(sticker.name)
                    .font(.caption2)
                    .foregroundStyle(Color.matchaForest)
                    .lineLimit(1)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .shadow(color: Color.matchaForest.opacity(0.1), radius: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Canvas Snapshot for Sharing

struct CanvasSnapshotView: View {
    let placedStickers: [PlacedSticker]
    let allStickers: [Sticker]
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.matchaSurface, Color.matchaSage.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Placed stickers
            ForEach(placedStickers) { placed in
                if let sticker = allStickers.first(where: { $0.id == placed.stickerID }) {
                    Image(systemName: sticker.imageName)
                        .font(.system(size: 50 * placed.scale))
                        .foregroundStyle(Color.matchaPrimary)
                        .rotationEffect(.radians(placed.rotation))
                        .offset(x: placed.x - 150, y: placed.y - 200)
                }
            }
            
            // Watermark
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "leaf.fill")
                    Text("Matcha")
                        .fontWeight(.bold)
                }
                .font(.caption)
                .foregroundStyle(Color.matchaPrimary.opacity(0.6))
                .padding(.bottom, 12)
            }
        }
        .frame(width: 300, height: 400)
    }
}

#Preview {
    StickerCanvasView()
        .modelContainer(for: [Sticker.self, PlacedSticker.self], inMemory: true)
}

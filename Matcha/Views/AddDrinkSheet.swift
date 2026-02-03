// AddDrinkSheet.swift
// Matcha

import SwiftUI
import SwiftData

struct AddDrinkSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomDrink.name) private var drinks: [CustomDrink]
    
    let onDrinkLogged: (Sticker?) -> Void
    
    @State private var showCreateDrink = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Create New button
                    createNewButton
                    
                    // Drinks grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(drinks) { drink in
                            DrinkCard(drink: drink) {
                                logDrink(drink)
                            }
                            .contextMenu {
                                if !drink.isDefault {
                                    Button(role: .destructive) {
                                        deleteDrink(drink)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.matchaSurface)
            .navigationTitle("Add Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.matchaForest)
                }
            }
            .sheet(isPresented: $showCreateDrink) {
                CreateDrinkView()
            }
        }
    }
    
    private var createNewButton: some View {
        Button {
            showCreateDrink = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Create New Drink")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.matchaPrimary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.matchaPrimary.opacity(0.1))
                    )
            )
            .foregroundStyle(Color.matchaPrimary)
        }
    }
    
    private func logDrink(_ drink: CustomDrink) {
        let service = DrinkService(modelContext: modelContext)
        do {
            let sticker = try service.logDrink(drink: drink)
            dismiss()
            onDrinkLogged(sticker)
        } catch {
            print("Failed to log drink: \(error)")
            dismiss()
            onDrinkLogged(nil)
        }
    }
    
    private func deleteDrink(_ drink: CustomDrink) {
        modelContext.delete(drink)
        try? modelContext.save()
    }
}

struct DrinkCard: View {
    let drink: CustomDrink
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(drink.emoji)
                    .font(.system(size: 44))
                
                Text(drink.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.matchaForest)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(drink.caffeineMg)", systemImage: "bolt.fill")
                    Label("\(drink.calories)", systemImage: "flame.fill")
                }
                .font(.caption2)
                .foregroundStyle(Color.matchaSage)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
                    .shadow(color: Color.matchaForest.opacity(0.1), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddDrinkSheet(onDrinkLogged: { _ in })
        .modelContainer(for: [DrinkLog.self, Sticker.self, UserStats.self, CustomDrink.self], inMemory: true)
}

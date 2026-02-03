// CreateDrinkView.swift
// Matcha

import SwiftUI
import SwiftData

struct CreateDrinkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var calories = 0
    @State private var caffeineMg = 0
    @State private var category: DrinkCategory = .tea
    @State private var emoji = "🍵"
    
    private let emojis = ["🍵", "☕️", "🧋", "🫖", "💧", "🥤", "🧃", "🥛", "🍶", "🍹"]
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Drink Info") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(DrinkCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Nutrition") {
                    Stepper("Calories: \(calories)", value: $calories, in: 0...1000, step: 10)
                    Stepper("Caffeine: \(caffeineMg) mg", value: $caffeineMg, in: 0...500, step: 5)
                }
                
                Section("Emoji") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(emojis, id: \.self) { e in
                            Text(e)
                                .font(.title)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(emoji == e ? Color.matchaPrimary.opacity(0.3) : Color.clear)
                                )
                                .onTapGesture {
                                    emoji = e
                                }
                        }
                    }
                }
            }
            .navigationTitle("New Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDrink()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveDrink() {
        let drink = CustomDrink(
            name: name.trimmingCharacters(in: .whitespaces),
            calories: calories,
            caffeineMg: caffeineMg,
            category: category.rawValue,
            emoji: emoji,
            isDefault: false
        )
        modelContext.insert(drink)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    CreateDrinkView()
        .modelContainer(for: CustomDrink.self, inMemory: true)
}

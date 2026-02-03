// ComposeReviewView.swift
// Matcha

import SwiftUI

struct ComposeReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cloudKit = CloudKitManager.shared
    
    @State private var drinkName = ""
    @State private var rating = 4
    @State private var reviewText = ""
    @State private var isPosting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var canPost: Bool {
        !drinkName.trimmingCharacters(in: .whitespaces).isEmpty && !isPosting
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("What did you drink?") {
                    TextField("Drink name", text: $drinkName)
                }
                
                Section("Rating") {
                    starPicker
                }
                
                Section("Thoughts?") {
                    TextEditor(text: $reviewText)
                        .frame(minHeight: 100)
                }
                
                Section {
                    HStack {
                        Text("Posting as")
                            .foregroundStyle(Color.matchaSage)
                        Spacer()
                        Text(CloudKitManager.userTeaName)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.matchaForest)
                    }
                } footer: {
                    Text("Your tea name is randomly generated for privacy")
                }
            }
            .navigationTitle("New Sip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.matchaForest)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        postReview()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canPost ? Color.matchaPrimary : Color.matchaSage)
                    .disabled(!canPost)
                }
            }
            .overlay {
                if isPosting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Posting...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var starPicker: some View {
        HStack(spacing: 12) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        rating = star
                    }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(star <= rating ? Color.matchaSuccess : Color.matchaSage.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Text(ratingLabel)
                .font(.caption)
                .foregroundStyle(Color.matchaSage)
        }
    }
    
    private var ratingLabel: String {
        switch rating {
        case 1: return "Not for me"
        case 2: return "It's okay"
        case 3: return "Good"
        case 4: return "Great!"
        case 5: return "Amazing!"
        default: return ""
        }
    }
    
    private func postReview() {
        isPosting = true
        
        Task {
            do {
                try await cloudKit.postReview(
                    drinkName: drinkName.trimmingCharacters(in: .whitespaces),
                    rating: rating,
                    text: reviewText.trimmingCharacters(in: .whitespacesAndNewlines),
                    authorName: CloudKitManager.userTeaName
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isPosting = false
            }
        }
    }
}

#Preview {
    ComposeReviewView()
}

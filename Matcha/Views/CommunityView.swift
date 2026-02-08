// CommunityView.swift
// Matcha

import SwiftUI

struct CommunityView: View {
    @ObservedObject private var cloudKit = CloudKitManager.shared
    @State private var showCompose = false
    @State private var showReportConfirmation = false
    
    // UGC Safety: Local blacklists for App Store compliance
    @AppStorage("blockedUserIDs") private var blockedUserIDsRaw: String = ""
    @AppStorage("reportedPostIDs") private var reportedPostIDsRaw: String = ""
    
    private var blockedUserIDs: Set<String> {
        Set(blockedUserIDsRaw.split(separator: ",").map(String.init))
    }
    
    private var reportedPostIDs: Set<String> {
        Set(reportedPostIDsRaw.split(separator: ",").map(String.init))
    }
    
    /// Filtered reviews excluding blocked users and reported posts
    private var filteredReviews: [DrinkReview] {
        cloudKit.reviews.filter { review in
            !blockedUserIDs.contains(review.authorName) &&
            !reportedPostIDs.contains(review.id.uuidString)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.matchaSurface
                    .ignoresSafeArea()
                
                if cloudKit.isLoading && cloudKit.reviews.isEmpty {
                    ProgressView("Loading sips...")
                        .foregroundStyle(Color.matchaForest)
                } else if let error = cloudKit.error, cloudKit.reviews.isEmpty {
                    errorView(error)
                } else if filteredReviews.isEmpty {
                    emptyStateView
                } else {
                    reviewList
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        fabButton
                    }
                }
                .padding()
            }
            .navigationTitle("Community")
            .refreshable {
                await cloudKit.fetchRecentReviews()
            }
            .task {
                if cloudKit.reviews.isEmpty {
                    await cloudKit.fetchRecentReviews()
                }
            }
            .sheet(isPresented: $showCompose) {
                ComposeReviewView()
            }
            .alert("Thank You", isPresented: $showReportConfirmation) {
                Button("OK") { }
            } message: {
                Text("Thanks for reporting. We will review this content.")
            }
        }
    }
    
    private var reviewList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredReviews) { review in
                    ReviewCard(review: review)
                        .contextMenu {
                            Button(role: .destructive) {
                                reportPost(review)
                            } label: {
                                Label("Report this Post", systemImage: "exclamationmark.bubble")
                            }
                            
                            Button(role: .destructive) {
                                blockUser(review.authorName)
                            } label: {
                                Label("Block User", systemImage: "hand.raised")
                            }
                        }
                }
            }
            .padding()
            .padding(.bottom, 80) // Space for FAB
        }
    }
    
    private var fabButton: some View {
        Button {
            showCompose = true
        } label: {
            Image(systemName: "pencil")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.matchaPrimary)
                .clipShape(Circle())
                .shadow(color: Color.matchaPrimary.opacity(0.4), radius: 8, y: 4)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(Color.matchaSage)
            
            Text("No sips yet!")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.matchaForest)
            
            Text("Be the first to share your drink")
                .font(.subheadline)
                .foregroundStyle(Color.matchaSage)
            
            Button {
                showCompose = true
            } label: {
                Text("Post a Sip")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.matchaPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color.matchaSage)
            
            Text("Couldn't load feed")
                .font(.headline)
                .foregroundStyle(Color.matchaForest)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.matchaSage)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await cloudKit.fetchRecentReviews()
                }
            }
            .foregroundStyle(Color.matchaPrimary)
        }
        .padding()
    }
    
    // MARK: - UGC Safety Actions
    
    private func reportPost(_ review: DrinkReview) {
        let postID = review.id.uuidString
        if !reportedPostIDsRaw.isEmpty {
            reportedPostIDsRaw += ","
        }
        reportedPostIDsRaw += postID
        showReportConfirmation = true
    }
    
    private func blockUser(_ authorName: String) {
        if !blockedUserIDsRaw.isEmpty {
            blockedUserIDsRaw += ","
        }
        blockedUserIDsRaw += authorName
        showReportConfirmation = true
    }
}

// MARK: - Review Card

struct ReviewCard: View {
    let review: DrinkReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Drink name
            Text(review.drinkName)
                .font(.headline)
                .foregroundStyle(Color.matchaForest)
            
            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(star <= review.rating ? Color.matchaSuccess : Color.matchaSage.opacity(0.5))
                }
            }
            
            // Review text
            if !review.reviewText.isEmpty {
                Text(review.reviewText)
                    .font(.subheadline)
                    .foregroundStyle(Color.matchaForest.opacity(0.85))
                    .lineLimit(4)
            }
            
            // Footer
            HStack {
                Text("Posted by \(review.authorName)")
                Text("•")
                Text(review.timeAgo)
            }
            .font(.caption)
            .foregroundStyle(Color.matchaSage)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.matchaAccent.opacity(0.5))
        )
    }
}

#Preview {
    CommunityView()
}

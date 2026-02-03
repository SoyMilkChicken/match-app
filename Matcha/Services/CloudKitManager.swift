// CloudKitManager.swift
// Matcha

import Foundation
import CloudKit

@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    // Lazy initialization prevents crash on launch if CloudKit is misconfigured
    private lazy var container: CKContainer = {
        CKContainer.default()
    }()
    
    private lazy var publicDatabase: CKDatabase = {
        container.publicCloudDatabase
    }()
    
    @Published var reviews: [DrinkReview] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isCloudKitAvailable = true
    
    private init() {
        // Empty - container/database are lazy loaded when first accessed
    }
    
    /// Fetch the latest 30 reviews from the public database
    func fetchRecentReviews() async {
        isLoading = true
        error = nil
        
        // Check CloudKit account status first
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                isCloudKitAvailable = false
                error = cloudKitErrorMessage(for: status)
                isLoading = false
                return
            }
        } catch {
            self.error = "CloudKit unavailable: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: DrinkReview.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: DrinkReview.FieldKey.timestamp, ascending: false)]
        
        do {
            let (results, _) = try await publicDatabase.records(
                matching: query,
                resultsLimit: 30
            )
            
            var fetchedReviews: [DrinkReview] = []
            for (_, result) in results {
                if case .success(let record) = result,
                   let review = DrinkReview(record: record) {
                    fetchedReviews.append(review)
                }
            }
            
            reviews = fetchedReviews
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Post a new review to the public database
    func postReview(drinkName: String, rating: Int, text: String, authorName: String) async throws {
        // Verify CloudKit is available before posting
        let status = try await container.accountStatus()
        guard status == .available else {
            throw CloudKitError.accountNotAvailable(status)
        }
        
        let review = DrinkReview(
            drinkName: drinkName,
            rating: rating,
            reviewText: text,
            authorName: authorName
        )
        
        let record = review.toRecord()
        
        _ = try await publicDatabase.save(record)
        
        // Refresh the feed
        await fetchRecentReviews()
    }
    
    private func cloudKitErrorMessage(for status: CKAccountStatus) -> String {
        switch status {
        case .couldNotDetermine:
            return "Could not determine iCloud status"
        case .noAccount:
            return "Please sign in to iCloud in Settings"
        case .restricted:
            return "iCloud access is restricted"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "iCloud unavailable"
        }
    }
}

// MARK: - Errors

enum CloudKitError: LocalizedError {
    case accountNotAvailable(CKAccountStatus)
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account not available. Please sign in to iCloud."
        }
    }
}

// MARK: - User Identity (Tea Name)

extension CloudKitManager {
    private static let teaNameKey = "matcha_user_tea_name"
    
    static let teaNames = [
        "Matcha Maven", "Boba Buddy", "Tea Enthusiast",
        "Oolong Observer", "Chai Champion", "Latte Lover",
        "Brew Boss", "Steep Seeker", "Herbal Hero",
        "Caffeine Curator", "Sipping Sage", "Infusion Fan"
    ]
    
    /// Get or generate the user's tea name
    static var userTeaName: String {
        get {
            if let name = UserDefaults.standard.string(forKey: teaNameKey) {
                return name
            }
            let randomName = teaNames.randomElement() ?? "Tea Lover"
            UserDefaults.standard.set(randomName, forKey: teaNameKey)
            return randomName
        }
        set {
            UserDefaults.standard.set(newValue, forKey: teaNameKey)
        }
    }
}

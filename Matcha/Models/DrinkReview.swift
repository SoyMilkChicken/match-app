// DrinkReview.swift
// Matcha

import Foundation
import CloudKit

struct DrinkReview: Identifiable, Sendable {
    let id: UUID
    let drinkName: String
    let rating: Int  // 1-5
    let reviewText: String
    let timestamp: Date
    let authorName: String
    let recordID: CKRecord.ID?
    
    // CloudKit record type
    static let recordType = "DrinkReview"
    
    // CloudKit field keys
    enum FieldKey {
        static let id = "id"
        static let drinkName = "drinkName"
        static let rating = "rating"
        static let reviewText = "reviewText"
        static let timestamp = "timestamp"
        static let authorName = "authorName"
    }
    
    init(
        id: UUID = UUID(),
        drinkName: String,
        rating: Int,
        reviewText: String,
        timestamp: Date = Date(),
        authorName: String,
        recordID: CKRecord.ID? = nil
    ) {
        self.id = id
        self.drinkName = drinkName
        self.rating = rating
        self.reviewText = reviewText
        self.timestamp = timestamp
        self.authorName = authorName
        self.recordID = recordID
    }
    
    /// Initialize from CloudKit record
    init?(record: CKRecord) {
        guard
            let uuidString = record[FieldKey.id] as? String,
            let uuid = UUID(uuidString: uuidString),
            let drinkName = record[FieldKey.drinkName] as? String,
            let rating = record[FieldKey.rating] as? Int,
            let reviewText = record[FieldKey.reviewText] as? String,
            let timestamp = record[FieldKey.timestamp] as? Date,
            let authorName = record[FieldKey.authorName] as? String
        else {
            return nil
        }
        
        self.id = uuid
        self.drinkName = drinkName
        self.rating = rating
        self.reviewText = reviewText
        self.timestamp = timestamp
        self.authorName = authorName
        self.recordID = record.recordID
    }
    
    /// Convert to CloudKit record
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType)
        record[FieldKey.id] = id.uuidString
        record[FieldKey.drinkName] = drinkName
        record[FieldKey.rating] = rating
        record[FieldKey.reviewText] = reviewText
        record[FieldKey.timestamp] = timestamp
        record[FieldKey.authorName] = authorName
        return record
    }
}

// MARK: - Time Ago Formatting

extension DrinkReview {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

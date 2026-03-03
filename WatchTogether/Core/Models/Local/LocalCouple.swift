import SwiftData
import Foundation

/// Cached representation of the user's couple, stored locally via SwiftData.
/// Only one instance should exist per user at any time.
@Model
final class LocalCouple {

    /// Firestore couples/{coupleId} document ID.
    @Attribute(.unique) var id: String
    var partnerDisplayName: String
    var partnerPhotoURL: String?
    var lastSyncedAt: Date

    init(
        id: String,
        partnerDisplayName: String,
        partnerPhotoURL: String? = nil,
        lastSyncedAt: Date = .now
    ) {
        self.id = id
        self.partnerDisplayName = partnerDisplayName
        self.partnerPhotoURL = partnerPhotoURL
        self.lastSyncedAt = lastSyncedAt
    }
}

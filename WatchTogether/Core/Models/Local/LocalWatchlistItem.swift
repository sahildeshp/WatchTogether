import SwiftData
import Foundation

/// Cached representation of a watchlist item stored locally via SwiftData.
/// Mirrors the Firestore document shape for both My List and Couple List entries.
@Model
final class LocalWatchlistItem {

    // MARK: - Identity

    /// Firestore document ID (used for deduplication and Firestore sync).
    @Attribute(.unique) var id: String
    var tmdbId: Int
    /// "movie" or "tv"
    var mediaType: String

    // MARK: - Metadata (denormalised from TMDB at write time)

    var title: String
    var posterPath: String
    var releaseYear: Int

    // MARK: - List state

    /// "want" | "watching" | "watched"
    var status: String
    /// 1–10, only set when status == "watched"
    var rating: Int?
    /// true → item lives in the couple's shared list; false → user's private list
    var isInCoupleList: Bool

    // MARK: - Timestamps

    var addedAt: Date
    var watchedAt: Date?
    var lastSyncedAt: Date

    init(
        id: String,
        tmdbId: Int,
        mediaType: String,
        title: String,
        posterPath: String,
        releaseYear: Int,
        status: String = "want",
        rating: Int? = nil,
        isInCoupleList: Bool = false,
        addedAt: Date = .now,
        watchedAt: Date? = nil,
        lastSyncedAt: Date = .now
    ) {
        self.id = id
        self.tmdbId = tmdbId
        self.mediaType = mediaType
        self.title = title
        self.posterPath = posterPath
        self.releaseYear = releaseYear
        self.status = status
        self.rating = rating
        self.isInCoupleList = isInCoupleList
        self.addedAt = addedAt
        self.watchedAt = watchedAt
        self.lastSyncedAt = lastSyncedAt
    }
}

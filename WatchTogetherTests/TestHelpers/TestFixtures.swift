import Foundation
@testable import WatchTogether

// MARK: - WatchlistItem test init

extension WatchlistItem {
    /// Convenience initializer available only in the test target.
    init(
        id: String,
        tmdbId: Int,
        mediaType: String,
        title: String,
        posterPath: String,
        releaseYear: Int,
        status: WatchlistStatus,
        rating: Int?,
        addedAt: Date,
        watchedAt: Date?
    ) {
        self.id          = id
        self.tmdbId      = tmdbId
        self.mediaType   = mediaType
        self.title       = title
        self.posterPath  = posterPath
        self.releaseYear = releaseYear
        self.status      = status
        self.rating      = rating
        self.addedAt     = addedAt
        self.watchedAt   = watchedAt
    }
}

// MARK: - CoupleWatchlistItem test init

extension CoupleWatchlistItem {
    /// Convenience initializer available only in the test target.
    init(
        id: String,
        tmdbId: Int,
        mediaType: String,
        title: String,
        posterPath: String,
        releaseYear: Int,
        nominatedBy: String,
        status: WatchlistStatus,
        ratings: [String: Int],
        addedAt: Date,
        watchedAt: Date?,
        watchedBy: String?
    ) {
        self.id          = id
        self.tmdbId      = tmdbId
        self.mediaType   = mediaType
        self.title       = title
        self.posterPath  = posterPath
        self.releaseYear = releaseYear
        self.nominatedBy = nominatedBy
        self.status      = status
        self.ratings     = ratings
        self.addedAt     = addedAt
        self.watchedAt   = watchedAt
        self.watchedBy   = watchedBy
    }
}

import Foundation

/// A unified history entry representing a watched item from either
/// the personal watchlist or the couple watchlist.
struct HistoryEntry: Identifiable {

    enum Source {
        case myList
        case ourList
    }

    /// Unique across both lists: `"personal-{id}"` or `"couple-{id}"`.
    let id: String
    let tmdbId: Int
    /// `"movie"` or `"tv"`
    let mediaType: String
    let title: String
    let posterPath: String
    let releaseYear: Int
    let watchedAt: Date?
    let source: Source
    /// Personal 1–10 rating (nil until rated; always nil for ourList entries).
    let myRating: Int?
    /// Couple ratings keyed by userId (empty for myList entries).
    let coupleRatings: [String: Int]

    var sortDate: Date { watchedAt ?? .distantPast }

    // MARK: - Factory

    init(from item: WatchlistItem) {
        self.id           = "personal-\(item.id)"
        self.tmdbId       = item.tmdbId
        self.mediaType    = item.mediaType
        self.title        = item.title
        self.posterPath   = item.posterPath
        self.releaseYear  = item.releaseYear
        self.watchedAt    = item.watchedAt
        self.source       = .myList
        self.myRating     = item.rating
        self.coupleRatings = [:]
    }

    init(from item: CoupleWatchlistItem) {
        self.id           = "couple-\(item.id)"
        self.tmdbId       = item.tmdbId
        self.mediaType    = item.mediaType
        self.title        = item.title
        self.posterPath   = item.posterPath
        self.releaseYear  = item.releaseYear
        self.watchedAt    = item.watchedAt
        self.source       = .ourList
        self.myRating     = nil
        self.coupleRatings = item.ratings
    }
}

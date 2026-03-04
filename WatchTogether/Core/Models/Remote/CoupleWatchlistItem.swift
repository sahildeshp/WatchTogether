import Foundation

/// A single entry in a couple's shared watchlist, persisted to Firestore under
/// `couples/{coupleId}/watchlist/{itemId}`.
struct CoupleWatchlistItem: Codable, Identifiable, Sendable {

    /// `"{tmdbId}-{mediaType}"` — used as Firestore document ID.
    let id: String
    let tmdbId: Int
    /// `"movie"` or `"tv"`
    let mediaType: String
    let title: String
    let posterPath: String
    let releaseYear: Int
    /// The userId of whoever nominated this item.
    let nominatedBy: String
    var status: WatchlistStatus
    /// `[userId: rating]` — up to two entries, one per partner.
    var ratings: [String: Int]
    let addedAt: Date
    var watchedAt: Date?
    var watchedBy: String?

    static func docId(tmdbId: Int, mediaType: String) -> String {
        "\(tmdbId)-\(mediaType)"
    }

    init(from result: TMDBSearchResult, nominatedBy: String) {
        self.id          = CoupleWatchlistItem.docId(tmdbId: result.id, mediaType: result.mediaType.rawValue)
        self.tmdbId      = result.id
        self.mediaType   = result.mediaType.rawValue
        self.title       = result.title
        self.posterPath  = result.posterPath ?? ""
        self.releaseYear = result.releaseYear ?? 0
        self.nominatedBy = nominatedBy
        self.status      = .want
        self.ratings     = [:]
        self.addedAt     = .now
        self.watchedAt   = nil
        self.watchedBy   = nil
    }
}

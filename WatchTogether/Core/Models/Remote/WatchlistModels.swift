import Foundation

// MARK: - Status

enum WatchlistStatus: String, Codable, CaseIterable, Sendable {
    case want     = "want"
    case watching = "watching"
    case watched  = "watched"

    var label: String {
        switch self {
        case .want:     "Want to Watch"
        case .watching: "Watching"
        case .watched:  "Watched"
        }
    }

    var icon: String {
        switch self {
        case .want:     "bookmark"
        case .watching: "play.circle"
        case .watched:  "checkmark.circle.fill"
        }
    }
}

// MARK: - Item

/// A single entry in a user's personal watchlist, persisted to Firestore.
/// The Firestore document ID equals `id` (stored redundantly in the body for easy decoding).
struct WatchlistItem: Codable, Identifiable, Sendable {

    /// `"{tmdbId}-{mediaType}"` — used as Firestore document ID.
    let id: String
    let tmdbId: Int
    /// `"movie"` or `"tv"`
    let mediaType: String
    let title: String
    let posterPath: String
    let releaseYear: Int
    var status: WatchlistStatus
    /// 1–10; `nil` until the item is rated.
    var rating: Int?
    let addedAt: Date
    var watchedAt: Date?

    // MARK: - Factory helpers

    static func docId(tmdbId: Int, mediaType: String) -> String {
        "\(tmdbId)-\(mediaType)"
    }

    /// Convenience initialiser from a TMDB search result.
    init(from result: TMDBSearchResult, status: WatchlistStatus = .want) {
        self.id         = WatchlistItem.docId(tmdbId: result.id, mediaType: result.mediaType.rawValue)
        self.tmdbId     = result.id
        self.mediaType  = result.mediaType.rawValue
        self.title      = result.title
        self.posterPath = result.posterPath ?? ""
        self.releaseYear = result.releaseYear ?? 0
        self.status     = status
        self.rating     = nil
        self.addedAt    = .now
        self.watchedAt  = nil
    }
}

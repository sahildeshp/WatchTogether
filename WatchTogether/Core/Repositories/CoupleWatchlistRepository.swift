import Foundation

protocol CoupleWatchlistRepository: Sendable {
    /// Real-time stream of the couple's shared watchlist, newest first.
    func watchCoupleList(coupleId: String) -> AsyncStream<[CoupleWatchlistItem]>

    /// Add a new item (or overwrite if the same `id` already exists).
    func add(item: CoupleWatchlistItem, coupleId: String) async throws

    /// Update the status of an existing item.
    func updateStatus(coupleId: String, itemId: String, status: WatchlistStatus, watchedBy: String?) async throws

    /// Set or update one partner's rating (1–10).
    func updateRating(coupleId: String, itemId: String, userId: String, rating: Int) async throws

    /// Remove an item from the couple list.
    func remove(coupleId: String, itemId: String) async throws
}

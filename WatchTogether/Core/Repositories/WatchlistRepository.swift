import Foundation

protocol WatchlistRepository: Sendable {
    /// Real-time stream of the user's personal watchlist, newest first.
    func watchMyList(userId: String) -> AsyncStream<[WatchlistItem]>

    /// Add a new item (or overwrite if the same `id` already exists).
    func add(item: WatchlistItem, userId: String) async throws

    /// Update the status of an existing item.
    func updateStatus(userId: String, itemId: String, status: WatchlistStatus) async throws

    /// Set or update the rating (1–10) of a watched item.
    func updateRating(userId: String, itemId: String, rating: Int) async throws

    /// Remove an item from the list.
    func remove(userId: String, itemId: String) async throws
}

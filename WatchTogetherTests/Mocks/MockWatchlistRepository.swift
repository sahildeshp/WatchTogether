import Foundation
@testable import WatchTogether

/// In-memory mock of `WatchlistRepository` for unit tests.
final class MockWatchlistRepository: WatchlistRepository, @unchecked Sendable {

    // MARK: - Controllable state

    /// Seed items that `watchMyList` will emit immediately.
    var items: [WatchlistItem] = []
    var addError: Error?
    var updateStatusError: Error?
    var updateRatingError: Error?
    var removeError: Error?

    // MARK: - Call tracking

    private(set) var addedItems: [WatchlistItem] = []
    private(set) var statusUpdates: [(itemId: String, status: WatchlistStatus)] = []
    private(set) var ratingUpdates: [(itemId: String, rating: Int)] = []
    private(set) var removedItemIds: [String] = []

    // MARK: - WatchlistRepository

    func watchMyList(userId: String) -> AsyncStream<[WatchlistItem]> {
        let snapshot = items
        return AsyncStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }

    func add(item: WatchlistItem, userId: String) async throws {
        if let error = addError { throw error }
        addedItems.append(item)
        items.append(item)
    }

    func updateStatus(userId: String, itemId: String, status: WatchlistStatus) async throws {
        if let error = updateStatusError { throw error }
        statusUpdates.append((itemId, status))
        if let idx = items.firstIndex(where: { $0.id == itemId }) {
            items[idx].status = status
        }
    }

    func updateRating(userId: String, itemId: String, rating: Int) async throws {
        if let error = updateRatingError { throw error }
        ratingUpdates.append((itemId, rating))
        if let idx = items.firstIndex(where: { $0.id == itemId }) {
            items[idx].rating = rating
        }
    }

    func remove(userId: String, itemId: String) async throws {
        if let error = removeError { throw error }
        removedItemIds.append(itemId)
        items.removeAll { $0.id == itemId }
    }
}

import Foundation
@testable import WatchTogether

/// In-memory mock of `CoupleWatchlistRepository` for unit tests.
final class MockCoupleWatchlistRepository: CoupleWatchlistRepository, @unchecked Sendable {

    // MARK: - Controllable state

    var items: [CoupleWatchlistItem] = []
    var addError: Error?
    var updateStatusError: Error?
    var updateRatingError: Error?
    var removeError: Error?

    // MARK: - Call tracking

    private(set) var addedItems: [CoupleWatchlistItem] = []
    private(set) var statusUpdates: [(itemId: String, status: WatchlistStatus)] = []
    private(set) var ratingUpdates: [(itemId: String, userId: String, rating: Int)] = []
    private(set) var removedItemIds: [String] = []

    // MARK: - CoupleWatchlistRepository

    func watchCoupleList(coupleId: String) -> AsyncStream<[CoupleWatchlistItem]> {
        let snapshot = items
        return AsyncStream { continuation in
            continuation.yield(snapshot)
            continuation.finish()
        }
    }

    func add(item: CoupleWatchlistItem, coupleId: String) async throws {
        if let error = addError { throw error }
        addedItems.append(item)
        items.append(item)
    }

    func updateStatus(coupleId: String, itemId: String, status: WatchlistStatus, watchedBy: String?) async throws {
        if let error = updateStatusError { throw error }
        statusUpdates.append((itemId, status))
        if let idx = items.firstIndex(where: { $0.id == itemId }) {
            items[idx].status = status
            if status == .watched {
                items[idx].watchedAt = .now
                items[idx].watchedBy = watchedBy
            }
        }
    }

    func updateRating(coupleId: String, itemId: String, userId: String, rating: Int) async throws {
        if let error = updateRatingError { throw error }
        ratingUpdates.append((itemId, userId, rating))
        if let idx = items.firstIndex(where: { $0.id == itemId }) {
            items[idx].ratings[userId] = rating
        }
    }

    func remove(coupleId: String, itemId: String) async throws {
        if let error = removeError { throw error }
        removedItemIds.append(itemId)
        items.removeAll { $0.id == itemId }
    }
}

import Foundation

@MainActor
@Observable
final class CoupleListViewModel {

    // MARK: - State

    private(set) var items: [CoupleWatchlistItem] = []
    private(set) var isLoading = true
    var errorMessage: String?
    var selectedStatus: WatchlistStatus = .want

    /// Controls the rating sheet.
    var showRatingPicker = false
    var itemToRate: CoupleWatchlistItem?

    /// Brief toast shown after a status change.
    var toastMessage: String?

    // MARK: - Derived

    var filteredItems: [CoupleWatchlistItem] {
        items.filter { $0.status == selectedStatus }
    }

    // MARK: - Internal (accessible to row views for rating/nomination display)

    let userId: String

    // MARK: - Private

    private let coupleId: String
    private let repository: CoupleWatchlistRepository
    nonisolated(unsafe) private var watchTask: Task<Void, Never>?

    // MARK: - Init / deinit

    init(
        coupleId: String,
        userId: String,
        repository: CoupleWatchlistRepository = FirestoreCoupleWatchlistRepository()
    ) {
        self.coupleId = coupleId
        self.userId = userId
        self.repository = repository
    }

    deinit { watchTask?.cancel() }

    // MARK: - Observation

    func startWatching() {
        watchTask?.cancel()
        watchTask = Task {
            for await newItems in repository.watchCoupleList(coupleId: coupleId) {
                guard !Task.isCancelled else { break }
                items = newItems
                isLoading = false
            }
        }
    }

    // MARK: - Mutations

    func updateStatus(item: CoupleWatchlistItem, to status: WatchlistStatus) async {
        do {
            let watchedBy = status == .watched ? userId : nil
            try await repository.updateStatus(coupleId: coupleId, itemId: item.id, status: status, watchedBy: watchedBy)
            showToast("Moved to \(status.label)")
            if status == .watched {
                itemToRate = items.first(where: { $0.id == item.id }) ?? item
                showRatingPicker = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rate(item: CoupleWatchlistItem, rating: Int) async {
        do {
            try await repository.updateRating(coupleId: coupleId, itemId: item.id, userId: userId, rating: rating)
            showRatingPicker = false
            itemToRate = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(item: CoupleWatchlistItem) async {
        do {
            try await repository.remove(coupleId: coupleId, itemId: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showToast(_ message: String) {
        toastMessage = message
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            self?.toastMessage = nil
        }
    }
}

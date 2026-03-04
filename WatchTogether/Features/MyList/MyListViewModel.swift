import Foundation

@MainActor
@Observable
final class MyListViewModel {

    // MARK: - State

    private(set) var items: [WatchlistItem] = []
    private(set) var isLoading = true
    var errorMessage: String?
    var selectedStatus: WatchlistStatus = .want

    /// Controls the rating sheet.
    var showRatingPicker = false
    var itemToRate: WatchlistItem?

    /// Brief toast shown after a status change.
    var toastMessage: String?

    // MARK: - Derived

    var filteredItems: [WatchlistItem] {
        items.filter { $0.status == selectedStatus }
    }

    // MARK: - Private

    private let userId: String
    private let repository: WatchlistRepository
    nonisolated(unsafe) private var watchTask: Task<Void, Never>?

    // MARK: - Init / deinit

    init(userId: String, repository: WatchlistRepository = FirestoreWatchlistRepository()) {
        self.userId = userId
        self.repository = repository
    }

    deinit { watchTask?.cancel() }

    // MARK: - Observation

    func startWatching() {
        watchTask?.cancel()
        watchTask = Task {
            for await newItems in repository.watchMyList(userId: userId) {
                guard !Task.isCancelled else { break }
                items = newItems
                isLoading = false
            }
        }
    }

    // MARK: - Mutations

    func updateStatus(item: WatchlistItem, to status: WatchlistStatus) async {
        do {
            try await repository.updateStatus(userId: userId, itemId: item.id, status: status)
            showToast("Moved to \(status.label)")
            if status == .watched {
                itemToRate = items.first(where: { $0.id == item.id }) ?? item
                showRatingPicker = true
            }
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

    func rate(item: WatchlistItem, rating: Int) async {
        do {
            try await repository.updateRating(userId: userId, itemId: item.id, rating: rating)
            showRatingPicker = false
            itemToRate = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(item: WatchlistItem) async {
        do {
            try await repository.remove(userId: userId, itemId: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

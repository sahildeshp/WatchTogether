import Testing
import Foundation
@testable import WatchTogether

// Tests for MyListViewModel using the mock repository.
// All tests run on the main actor because MyListViewModel is @MainActor.
@MainActor
struct MyListViewModelTests {

    // MARK: - Helpers

    private func makeItem(
        id: String = "1-movie",
        title: String = "Test Movie",
        status: WatchlistStatus = .want,
        rating: Int? = nil,
        watchedAt: Date? = nil
    ) -> WatchlistItem {
        WatchlistItem(
            id: id,
            tmdbId: 1,
            mediaType: "movie",
            title: title,
            posterPath: "",
            releaseYear: 2024,
            status: status,
            rating: rating,
            addedAt: .now,
            watchedAt: watchedAt
        )
    }

    // MARK: - startWatching

    @Test("startWatching populates items and clears isLoading")
    func startWatching_populatesItems() async {
        let repo = MockWatchlistRepository()
        repo.items = [makeItem(status: .want), makeItem(id: "2-tv", status: .watching)]
        let vm = MyListViewModel(userId: "u1", repository: repo)

        vm.startWatching()
        // Give the async stream a tick to deliver
        await Task.yield()

        #expect(vm.items.count == 2)
        #expect(!vm.isLoading)
    }

    // MARK: - filteredItems

    @Test("filteredItems returns only items matching selectedStatus")
    func filteredItems_filtersByStatus() async {
        let repo = MockWatchlistRepository()
        repo.items = [
            makeItem(id: "a", status: .want),
            makeItem(id: "b", status: .watching),
            makeItem(id: "c", status: .watched)
        ]
        let vm = MyListViewModel(userId: "u1", repository: repo)
        vm.startWatching()
        await Task.yield()

        vm.selectedStatus = .watching
        #expect(vm.filteredItems.count == 1)
        #expect(vm.filteredItems[0].id == "b")
    }

    // MARK: - updateStatus

    @Test("updateStatus calls repository and triggers rating sheet when watched")
    func updateStatus_toWatched_opensRatingPicker() async {
        let repo = MockWatchlistRepository()
        let item = makeItem(status: .want)
        repo.items = [item]
        let vm = MyListViewModel(userId: "u1", repository: repo)
        vm.startWatching()
        await Task.yield()

        await vm.updateStatus(item: item, to: .watched)

        #expect(repo.statusUpdates.count == 1)
        #expect(repo.statusUpdates[0].status == .watched)
        #expect(vm.showRatingPicker)
        #expect(vm.itemToRate != nil)
    }

    @Test("updateStatus sets errorMessage when repository throws")
    func updateStatus_errorPropagates() async {
        let repo = MockWatchlistRepository()
        repo.updateStatusError = NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Update failed"])
        let item = makeItem(status: .want)
        repo.items = [item]
        let vm = MyListViewModel(userId: "u1", repository: repo)
        vm.startWatching()
        await Task.yield()

        await vm.updateStatus(item: item, to: .watching)

        #expect(vm.errorMessage == "Update failed")
    }

    // MARK: - rate

    @Test("rate calls repository and dismisses picker")
    func rate_dismissesPicker() async {
        let repo = MockWatchlistRepository()
        let item = makeItem(status: .watched)
        repo.items = [item]
        let vm = MyListViewModel(userId: "u1", repository: repo)
        vm.startWatching()
        await Task.yield()
        vm.showRatingPicker = true
        vm.itemToRate = item

        await vm.rate(item: item, rating: 8)

        #expect(repo.ratingUpdates.count == 1)
        #expect(repo.ratingUpdates[0].rating == 8)
        #expect(!vm.showRatingPicker)
        #expect(vm.itemToRate == nil)
    }

    // MARK: - remove

    @Test("remove calls repository with correct itemId")
    func remove_callsRepository() async {
        let repo = MockWatchlistRepository()
        let item = makeItem(id: "42-movie", status: .want)
        repo.items = [item]
        let vm = MyListViewModel(userId: "u1", repository: repo)
        vm.startWatching()
        await Task.yield()

        await vm.remove(item: item)

        #expect(repo.removedItemIds == ["42-movie"])
    }
}

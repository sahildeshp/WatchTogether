import Testing
import Foundation
@testable import WatchTogether

@MainActor
struct WatchHistoryViewModelTests {

    // MARK: - Helpers

    private func makePersonalItem(
        id: String = "1-movie",
        mediaType: String = "movie",
        watchedAt: Date? = .now
    ) -> WatchlistItem {
        WatchlistItem(
            id: id,
            tmdbId: 1,
            mediaType: mediaType,
            title: "Movie \(id)",
            posterPath: "",
            releaseYear: 2024,
            status: .watched,
            rating: nil,
            addedAt: .now,
            watchedAt: watchedAt
        )
    }

    private func makeCoupleItem(
        id: String = "2-tv",
        mediaType: String = "tv",
        watchedAt: Date? = .now
    ) -> CoupleWatchlistItem {
        CoupleWatchlistItem(
            id: id,
            tmdbId: 2,
            mediaType: mediaType,
            title: "Show \(id)",
            posterPath: "",
            releaseYear: 2024,
            nominatedBy: "u1",
            status: .watched,
            ratings: [:],
            addedAt: .now,
            watchedAt: watchedAt,
            watchedBy: "u1"
        )
    }

    // MARK: - Entry merging

    @Test("allEntries merges personal and couple watched items, newest first")
    func allEntries_mergesAndSorts() async {
        let personalRepo = MockWatchlistRepository()
        let coupleRepo   = MockCoupleWatchlistRepository()

        let older = Date(timeIntervalSinceNow: -86400 * 7)
        let newer = Date(timeIntervalSinceNow: -3600)
        personalRepo.items = [makePersonalItem(watchedAt: older)]
        coupleRepo.items   = [makeCoupleItem(watchedAt: newer)]

        let vm = WatchHistoryViewModel(
            userId: "u1",
            coupleId: "c1",
            personalRepo: personalRepo,
            coupleRepo: coupleRepo
        )
        vm.startWatching()
        await Task.yield()

        #expect(vm.allEntries.count == 2)
        #expect(vm.allEntries[0].sortDate >= vm.allEntries[1].sortDate)
    }

    @Test("allEntries only includes non-couple entries when coupleId is nil")
    func allEntries_noCoupleId() async {
        let personalRepo = MockWatchlistRepository()
        let coupleRepo   = MockCoupleWatchlistRepository()
        personalRepo.items = [makePersonalItem()]
        coupleRepo.items   = [makeCoupleItem()]

        let vm = WatchHistoryViewModel(
            userId: "u1",
            coupleId: nil,
            personalRepo: personalRepo,
            coupleRepo: coupleRepo
        )
        vm.startWatching()
        await Task.yield()

        #expect(vm.allEntries.count == 1)
        #expect(vm.allEntries[0].source == .myList)
    }

    // MARK: - MediaFilter

    @Test("filteredEntries filters by movie type")
    func filteredEntries_movieFilter() async {
        let personalRepo = MockWatchlistRepository()
        let coupleRepo   = MockCoupleWatchlistRepository()
        personalRepo.items = [makePersonalItem(id: "a", mediaType: "movie")]
        coupleRepo.items   = [makeCoupleItem(id: "b", mediaType: "tv")]

        let vm = WatchHistoryViewModel(
            userId: "u1",
            coupleId: "c1",
            personalRepo: personalRepo,
            coupleRepo: coupleRepo
        )
        vm.startWatching()
        await Task.yield()

        vm.selectedFilter = .movie
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].mediaType == "movie")

        vm.selectedFilter = .tv
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].mediaType == "tv")
    }

    // MARK: - Grouping

    @Test("groupedEntries groups items by month-year section")
    func groupedEntries_groupsByMonth() async {
        let personalRepo = MockWatchlistRepository()
        let coupleRepo   = MockCoupleWatchlistRepository()

        // Two items in the same month, one in a different month
        var comps = DateComponents()
        comps.year = 2025; comps.month = 1; comps.day = 15
        let jan = Calendar.current.date(from: comps)!
        comps.month = 2
        let feb = Calendar.current.date(from: comps)!

        personalRepo.items = [
            makePersonalItem(id: "jan1", watchedAt: jan),
            makePersonalItem(id: "jan2", watchedAt: jan),
            makePersonalItem(id: "feb1", watchedAt: feb)
        ]

        let vm = WatchHistoryViewModel(
            userId: "u1",
            coupleId: nil,
            personalRepo: personalRepo,
            coupleRepo: coupleRepo
        )
        vm.startWatching()
        await Task.yield()

        // Items are sorted newest first, so February section comes first
        #expect(vm.groupedEntries.count == 2)
        #expect(vm.groupedEntries[0].entries.count == 1)  // Feb
        #expect(vm.groupedEntries[1].entries.count == 2)  // Jan
    }

    // MARK: - isLoading

    @Test("isLoading is false after first personal stream delivery")
    func isLoading_clearsAfterDelivery() async {
        let personalRepo = MockWatchlistRepository()
        let coupleRepo   = MockCoupleWatchlistRepository()
        personalRepo.items = []

        let vm = WatchHistoryViewModel(
            userId: "u1",
            coupleId: nil,
            personalRepo: personalRepo,
            coupleRepo: coupleRepo
        )
        #expect(vm.isLoading)

        vm.startWatching()
        await Task.yield()

        #expect(!vm.isLoading)
    }
}

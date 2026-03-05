import Testing
import Foundation
@testable import WatchTogether

struct HistoryEntryTests {

    // MARK: - init(from: WatchlistItem)

    @Test("HistoryEntry from WatchlistItem has prefixed id and myList source")
    func fromWatchlistItem() {
        let item = WatchlistItem(
            id: "42-movie",
            tmdbId: 42,
            mediaType: "movie",
            title: "Inception",
            posterPath: "/poster.jpg",
            releaseYear: 2010,
            status: .watched,
            rating: 9,
            addedAt: .now,
            watchedAt: .now
        )
        let entry = HistoryEntry(from: item)

        #expect(entry.id == "personal-42-movie")
        #expect(entry.source == .myList)
        #expect(entry.myRating == 9)
        #expect(entry.coupleRatings.isEmpty)
        #expect(entry.mediaType == "movie")
    }

    // MARK: - init(from: CoupleWatchlistItem)

    @Test("HistoryEntry from CoupleWatchlistItem has prefixed id and ourList source")
    func fromCoupleWatchlistItem() {
        let item = CoupleWatchlistItem(
            id: "10-tv",
            tmdbId: 10,
            mediaType: "tv",
            title: "Breaking Bad",
            posterPath: "/bb.jpg",
            releaseYear: 2008,
            nominatedBy: "user1",
            status: .watched,
            ratings: ["user1": 10, "user2": 9],
            addedAt: .now,
            watchedAt: .now,
            watchedBy: "user1"
        )
        let entry = HistoryEntry(from: item)

        #expect(entry.id == "couple-10-tv")
        #expect(entry.source == .ourList)
        #expect(entry.myRating == nil)
        #expect(entry.coupleRatings["user1"] == 10)
        #expect(entry.coupleRatings["user2"] == 9)
    }

    // MARK: - sortDate

    @Test("sortDate uses watchedAt when present, distantPast otherwise")
    func sortDate_fallsBack() {
        let withDate = WatchlistItem(
            id: "1-movie", tmdbId: 1, mediaType: "movie", title: "A",
            posterPath: "", releaseYear: 2020, status: .watched,
            rating: nil, addedAt: .now, watchedAt: .distantFuture
        )
        let withoutDate = WatchlistItem(
            id: "2-movie", tmdbId: 2, mediaType: "movie", title: "B",
            posterPath: "", releaseYear: 2020, status: .watched,
            rating: nil, addedAt: .now, watchedAt: nil
        )
        #expect(HistoryEntry(from: withDate).sortDate == .distantFuture)
        #expect(HistoryEntry(from: withoutDate).sortDate == .distantPast)
    }
}

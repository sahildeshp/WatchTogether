import Foundation

@MainActor
@Observable
final class WatchHistoryViewModel {

    // MARK: - Filter

    enum MediaFilter: String, CaseIterable {
        case all   = "All"
        case movie = "Movies"
        case tv    = "TV"
    }

    // MARK: - State

    private(set) var allEntries: [HistoryEntry] = []
    private(set) var isLoading = true
    var selectedFilter: MediaFilter = .all

    // MARK: - Derived

    var filteredEntries: [HistoryEntry] {
        switch selectedFilter {
        case .all:   allEntries
        case .movie: allEntries.filter { $0.mediaType == "movie" }
        case .tv:    allEntries.filter { $0.mediaType == "tv" }
        }
    }

    /// Entries grouped by month-year, newest section first.
    /// Preserves the sort order of `filteredEntries` within each section.
    var groupedEntries: [(monthYear: String, entries: [HistoryEntry])] {
        var keys: [String] = []
        var dict: [String: [HistoryEntry]] = [:]
        for entry in filteredEntries {
            let key = entry.watchedAt.map { Self.sectionFormatter.string(from: $0) } ?? "Earlier"
            if dict[key] == nil {
                dict[key] = []
                keys.append(key)
            }
            dict[key]!.append(entry)
        }
        return keys.map { ($0, dict[$0]!) }
    }

    // MARK: - Internal (exposed to row views)

    let userId: String

    // MARK: - Private

    private let coupleId: String?
    private let personalRepo: WatchlistRepository
    private let coupleRepo: CoupleWatchlistRepository

    private var personalWatched: [WatchlistItem] = []
    private var coupleWatched: [CoupleWatchlistItem] = []

    nonisolated(unsafe) private var personalTask: Task<Void, Never>?
    nonisolated(unsafe) private var coupleTask: Task<Void, Never>?

    private static let sectionFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    // MARK: - Init / deinit

    init(
        userId: String,
        coupleId: String?,
        personalRepo: WatchlistRepository = FirestoreWatchlistRepository(),
        coupleRepo: CoupleWatchlistRepository = FirestoreCoupleWatchlistRepository()
    ) {
        self.userId = userId
        self.coupleId = coupleId
        self.personalRepo = personalRepo
        self.coupleRepo = coupleRepo
    }

    deinit {
        personalTask?.cancel()
        coupleTask?.cancel()
    }

    // MARK: - Observation

    func startWatching() {
        personalTask?.cancel()
        coupleTask?.cancel()

        personalTask = Task {
            for await items in personalRepo.watchMyList(userId: userId) {
                guard !Task.isCancelled else { break }
                personalWatched = items.filter { $0.status == .watched }
                rebuildEntries()
                isLoading = false
            }
        }

        if let coupleId {
            coupleTask = Task {
                for await items in coupleRepo.watchCoupleList(coupleId: coupleId) {
                    guard !Task.isCancelled else { break }
                    coupleWatched = items.filter { $0.status == .watched }
                    rebuildEntries()
                }
            }
        }
    }

    // MARK: - Private helpers

    private func rebuildEntries() {
        let personal = personalWatched.map { HistoryEntry(from: $0) }
        let couple   = coupleWatched.map   { HistoryEntry(from: $0) }
        allEntries = (personal + couple).sorted { $0.sortDate > $1.sortDate }
    }
}

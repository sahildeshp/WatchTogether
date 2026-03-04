import Foundation

@MainActor
@Observable
final class ContentDetailViewModel {

    // MARK: - TMDB state

    private(set) var detail: TMDBDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Watchlist state

    private(set) var myListStatus: WatchlistStatus?   // nil = not in list
    private(set) var isAddingToList = false

    // MARK: - Dependencies

    private let result: TMDBSearchResult
    private let service: TMDBService
    private let watchlistRepo: WatchlistRepository
    /// Injected from the environment before `load()` is called.
    var userId: String?

    // MARK: - Init

    init(
        result: TMDBSearchResult,
        service: TMDBService = .shared,
        watchlistRepo: WatchlistRepository = FirestoreWatchlistRepository()
    ) {
        self.result = result
        self.service = service
        self.watchlistRepo = watchlistRepo
    }

    // MARK: - Load

    func load() async {
        guard detail == nil else { return }
        isLoading = true
        errorMessage = nil
        do {
            switch result.mediaType {
            case .movie:
                detail = .movie(try await service.movieDetail(id: result.id))
            case .tv:
                detail = .tv(try await service.tvDetail(id: result.id))
            case .person:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        await refreshMyListStatus()
    }

    // MARK: - Watchlist actions

    func addToMyList() async {
        guard let userId, myListStatus == nil else { return }
        isAddingToList = true
        let item = WatchlistItem(from: result)
        do {
            try await watchlistRepo.add(item: item, userId: userId)
            myListStatus = .want
        } catch {
            errorMessage = error.localizedDescription
        }
        isAddingToList = false
    }

    func removeFromMyList() async {
        guard let userId else { return }
        let itemId = WatchlistItem.docId(tmdbId: result.id, mediaType: result.mediaType.rawValue)
        do {
            try await watchlistRepo.remove(userId: userId, itemId: itemId)
            myListStatus = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private helpers

    private func refreshMyListStatus() async {
        guard let userId else { return }
        let itemId = WatchlistItem.docId(tmdbId: result.id, mediaType: result.mediaType.rawValue)
        // We watch the snapshot stream; just grab the first emission to seed the status.
        for await items in watchlistRepo.watchMyList(userId: userId) {
            myListStatus = items.first(where: { $0.id == itemId })?.status
            return   // only need the initial snapshot here
        }
    }
}

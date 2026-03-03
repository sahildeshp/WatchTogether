import Foundation

@MainActor
@Observable
final class ContentDetailViewModel {

    // MARK: - State

    private(set) var detail: TMDBDetail?
    private(set) var isLoading = false
    var errorMessage: String?

    // MARK: - Init

    private let result: TMDBSearchResult
    private let service: TMDBService

    init(result: TMDBSearchResult, service: TMDBService = .shared) {
        self.result = result
        self.service = service
    }

    // MARK: - Load

    func load() async {
        guard detail == nil else { return }  // already loaded (cache hit on second open)
        isLoading = true
        errorMessage = nil
        do {
            switch result.mediaType {
            case .movie:
                let movie = try await service.movieDetail(id: result.id)
                detail = .movie(movie)
            case .tv:
                let tv = try await service.tvDetail(id: result.id)
                detail = .tv(tv)
            case .person:
                break   // filtered out upstream; shouldn't reach here
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

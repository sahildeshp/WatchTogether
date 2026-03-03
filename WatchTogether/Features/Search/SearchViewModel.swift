import Foundation

@MainActor
@Observable
final class SearchViewModel {

    // MARK: - State

    var query: String = ""
    private(set) var results: [TMDBSearchResult] = []
    private(set) var isSearching = false
    var errorMessage: String?

    // MARK: - Dependencies

    let service: TMDBService   // `internal` so SearchView can pass it to ContentDetailViewModel

    // MARK: - Private

    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(service: TMDBService = .shared) {
        self.service = service
    }

    // MARK: - Search

    /// Call this from `.onChange(of: query)`.
    /// Debounces 300 ms and cancels any previous in-flight request.
    func onQueryChange(_ newValue: String) {
        searchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            isSearching = false
            return
        }

        searchTask = Task {
            // 300 ms debounce
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            errorMessage = nil

            do {
                results = try await service.search(query: trimmed)
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isSearching = false
        }
    }
}

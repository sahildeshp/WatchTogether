import Foundation

/// Async/await wrapper around the TMDB v3 REST API.
/// Results are cached in-memory for the lifetime of the app session.
final class TMDBService: Sendable {

    static let shared = TMDBService()

    // MARK: - Image URL helpers

    static func posterURL(_ path: String, size: String = "w342") -> URL? {
        URL(string: "https://image.tmdb.org/t/p/\(size)\(path)")
    }

    static func backdropURL(_ path: String) -> URL? {
        URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    static func profileURL(_ path: String) -> URL? {
        URL(string: "https://image.tmdb.org/t/p/w185\(path)")
    }

    // MARK: - Private

    private static let base = URL(string: "https://api.themoviedb.org/3")!

    private let apiKey: String
    private let session: URLSession
    private let cache = TMDBCache()

    init(session: URLSession = .shared) {
        apiKey = Bundle.main.infoDictionary?["TMDB_API_KEY"] as? String ?? ""
        self.session = session
    }

    // MARK: - API

    func search(query: String) async throws -> [TMDBSearchResult] {
        if let cached = await cache.searchResults(for: query) { return cached }

        let url = Self.base
            .appending(path: "search/multi")
            .appending(queryItems: [
                URLQueryItem(name: "api_key",        value: apiKey),
                URLQueryItem(name: "query",          value: query),
                URLQueryItem(name: "language",       value: "en-US"),
                URLQueryItem(name: "include_adult",  value: "false"),
                URLQueryItem(name: "page",           value: "1"),
            ])

        let (data, _) = try await session.data(from: url)
        let response = try decode(TMDBMultiSearchResponse.self, from: data)
        let results = response.results.filter { $0.mediaType != .person }
        await cache.setSearchResults(results, for: query)
        return results
    }

    func movieDetail(id: Int) async throws -> TMDBMovieDetail {
        if let cached = await cache.movie(id: id) { return cached }

        let url = Self.base
            .appending(path: "movie/\(id)")
            .appending(queryItems: [
                URLQueryItem(name: "api_key",              value: apiKey),
                URLQueryItem(name: "language",             value: "en-US"),
                URLQueryItem(name: "append_to_response",   value: "credits"),
            ])

        let (data, _) = try await session.data(from: url)
        let detail = try decode(TMDBMovieDetail.self, from: data)
        await cache.setMovie(detail, id: id)
        return detail
    }

    func tvDetail(id: Int) async throws -> TMDBTVDetail {
        if let cached = await cache.tv(id: id) { return cached }

        let url = Self.base
            .appending(path: "tv/\(id)")
            .appending(queryItems: [
                URLQueryItem(name: "api_key",              value: apiKey),
                URLQueryItem(name: "language",             value: "en-US"),
                URLQueryItem(name: "append_to_response",   value: "credits"),
            ])

        let (data, _) = try await session.data(from: url)
        let detail = try decode(TMDBTVDetail.self, from: data)
        await cache.setTV(detail, id: id)
        return detail
    }

    // MARK: - Decode helper

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(type, from: data)
    }
}

// MARK: - In-memory cache (actor for thread safety)

private actor TMDBCache {
    private var searches: [String: [TMDBSearchResult]] = [:]
    private var movies:   [Int: TMDBMovieDetail]       = [:]
    private var tvShows:  [Int: TMDBTVDetail]          = [:]

    func searchResults(for query: String) -> [TMDBSearchResult]? { searches[query] }
    func setSearchResults(_ r: [TMDBSearchResult], for query: String) { searches[query] = r }

    func movie(id: Int) -> TMDBMovieDetail? { movies[id] }
    func setMovie(_ d: TMDBMovieDetail, id: Int) { movies[id] = d }

    func tv(id: Int) -> TMDBTVDetail? { tvShows[id] }
    func setTV(_ d: TMDBTVDetail, id: Int) { tvShows[id] = d }
}

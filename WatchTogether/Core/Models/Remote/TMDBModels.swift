import Foundation

// MARK: - Search response

struct TMDBMultiSearchResponse: Decodable, Sendable {
    let results: [TMDBSearchResult]
}

// MARK: - Search result (movie or TV)

struct TMDBSearchResult: Decodable, Identifiable, Hashable, Sendable {

    let id: Int
    let mediaType: MediaType
    /// Normalised: uses "title" for movies and "name" for TV shows.
    let title: String
    let posterPath: String?
    let overview: String
    /// Parsed from `release_date` (movie) or `first_air_date` (TV).
    let releaseYear: Int?

    enum MediaType: String, Decodable, Hashable, Sendable {
        case movie, tv, person
    }

    // Custom init because the JSON field for the title differs by media type.
    // Raw values intentionally omitted: `.convertFromSnakeCase` converts JSON
    // keys (e.g. "media_type" → "mediaType") before matching CodingKey raw values,
    // so the raw value must equal the *camelCase* form, which is the default.
    private enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case mediaType      // matched from JSON "media_type"
        case posterPath     // matched from JSON "poster_path"
        case releaseDate    // matched from JSON "release_date"
        case firstAirDate   // matched from JSON "first_air_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try  c.decode(Int.self, forKey: .id)
        mediaType = (try? c.decode(MediaType.self, forKey: .mediaType)) ?? .movie
        overview  = (try? c.decode(String.self, forKey: .overview)) ?? ""
        posterPath = try? c.decode(String.self, forKey: .posterPath)

        // movie → "title" field, TV → "name" field
        let movieTitle = try? c.decode(String.self, forKey: .title)
        let tvName     = try? c.decode(String.self, forKey: .name)
        title = movieTitle ?? tvName ?? "Unknown"

        // Pull the year out of whichever date string is present
        let dateStr = (try? c.decode(String.self, forKey: .releaseDate))
                   ?? (try? c.decode(String.self, forKey: .firstAirDate))
        if let dateStr, dateStr.count >= 4, let year = Int(dateStr.prefix(4)) {
            releaseYear = year
        } else {
            releaseYear = nil
        }
    }
}

// MARK: - Movie detail  (GET /movie/{id}?append_to_response=credits)

struct TMDBMovieDetail: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let runtime: Int?
    let genres: [Genre]
    let credits: TMDBCredits?

    struct Genre: Decodable, Sendable {
        let id: Int
        let name: String
    }

    var releaseYear: Int? {
        guard let d = releaseDate, d.count >= 4 else { return nil }
        return Int(d.prefix(4))
    }

    var director: String? {
        credits?.crew.first(where: { $0.job == "Director" })?.name
    }

    var runtimeLabel: String? {
        guard let rt = runtime, rt > 0 else { return nil }
        let h = rt / 60; let m = rt % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - TV detail  (GET /tv/{id}?append_to_response=credits)

struct TMDBTVDetail: Decodable, Sendable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let numberOfSeasons: Int?
    let genres: [Genre]
    let credits: TMDBCredits?
    let createdBy: [Creator]

    struct Genre: Decodable, Sendable {
        let id: Int
        let name: String
    }

    struct Creator: Decodable, Sendable {
        let id: Int
        let name: String
    }

    var releaseYear: Int? {
        guard let d = firstAirDate, d.count >= 4 else { return nil }
        return Int(d.prefix(4))
    }

    var creator: String? { createdBy.first?.name }

    var seasonsLabel: String? {
        guard let s = numberOfSeasons else { return nil }
        return s == 1 ? "1 Season" : "\(s) Seasons"
    }
}

// MARK: - Credits

struct TMDBCredits: Decodable, Sendable {

    let cast: [CastMember]
    let crew: [CrewMember]

    struct CastMember: Decodable, Identifiable, Sendable {
        let id: Int
        let name: String
        let character: String?
        let profilePath: String?
    }

    struct CrewMember: Decodable, Identifiable, Sendable {
        let id: Int
        let name: String
        let job: String
        let department: String?
    }
}

// MARK: - Detail union  (convenience wrapper used by ContentDetailView)

enum TMDBDetail: Sendable {
    case movie(TMDBMovieDetail)
    case tv(TMDBTVDetail)

    var id: Int {
        switch self { case .movie(let m): m.id; case .tv(let t): t.id }
    }
    var title: String {
        switch self { case .movie(let m): m.title; case .tv(let t): t.name }
    }
    var overview: String {
        switch self { case .movie(let m): m.overview; case .tv(let t): t.overview }
    }
    var posterPath: String? {
        switch self { case .movie(let m): m.posterPath; case .tv(let t): t.posterPath }
    }
    var backdropPath: String? {
        switch self { case .movie(let m): m.backdropPath; case .tv(let t): t.backdropPath }
    }
    var releaseYear: Int? {
        switch self { case .movie(let m): m.releaseYear; case .tv(let t): t.releaseYear }
    }
    var genres: [String] {
        switch self {
        case .movie(let m): m.genres.map(\.name)
        case .tv(let t): t.genres.map(\.name)
        }
    }
    var credits: TMDBCredits? {
        switch self { case .movie(let m): m.credits; case .tv(let t): t.credits }
    }
    /// Director (movie) or show creator (TV).
    var directorOrCreator: String? {
        switch self { case .movie(let m): m.director; case .tv(let t): t.creator }
    }
    var runtimeOrSeasons: String? {
        switch self { case .movie(let m): m.runtimeLabel; case .tv(let t): t.seasonsLabel }
    }
    var mediaTypeLabel: String {
        switch self { case .movie: "Movie"; case .tv: "Series" }
    }
    var mediaType: TMDBSearchResult.MediaType {
        switch self { case .movie: .movie; case .tv: .tv }
    }
}

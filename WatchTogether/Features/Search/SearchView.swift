import SwiftUI
import Kingfisher

struct SearchView: View {

    @State private var vm = SearchViewModel()

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            Group {
                if vm.query.isEmpty {
                    emptyPrompt
                } else if vm.isSearching && vm.results.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.results.isEmpty {
                    noResults
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $vm.query, prompt: "Movies & TV shows…")
            .onChange(of: vm.query) { _, new in vm.onQueryChange(new) }
            .navigationDestination(for: TMDBSearchResult.self) { result in
                ContentDetailView(result: result, service: vm.service)
            }
        }
    }

    // MARK: - States

    private var emptyPrompt: some View {
        VStack(spacing: 14) {
            Image(systemName: "film.stack")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Search for a movie or TV show")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("No results for \"\(vm.query)\"")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        List(vm.results) { result in
            NavigationLink(value: result) {
                SearchResultRow(result: result)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
        .overlay(alignment: .top) {
            if vm.isSearching {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Result row

private struct SearchResultRow: View {

    let result: TMDBSearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Poster thumbnail
            posterThumbnail

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Media type badge
                    Text(result.mediaType == .movie ? "Movie" : "Series")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.purple.opacity(0.15), in: Capsule())
                        .foregroundStyle(.purple)

                    if let year = result.releaseYear {
                        Text(verbatim: "\(year)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !result.overview.isEmpty {
                    Text(result.overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
        }
    }

    private var posterThumbnail: some View {
        Group {
            if let path = result.posterPath, let url = TMDBService.posterURL(path, size: "w92") {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay {
                        Image(systemName: "film")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 54, height: 81)
        .clipShape(.rect(cornerRadius: 6))
    }
}

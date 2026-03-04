import SwiftUI
import Kingfisher

struct WatchHistoryView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var vm: WatchHistoryViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    HistoryContentView(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("History")
        }
        // Re-runs when coupleId changes so couple history appears after pairing
        .task(id: auth.currentUser?.coupleId) {
            guard let userId = auth.currentUser?.id else { return }
            let viewModel = WatchHistoryViewModel(userId: userId, coupleId: auth.currentUser?.coupleId)
            vm = viewModel
            viewModel.startWatching()
        }
    }
}

// MARK: - Content

@MainActor
private struct HistoryContentView: View {

    @Bindable var vm: WatchHistoryViewModel

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.allEntries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    filterPicker
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Divider().padding(.top, 8)
                    if vm.filteredEntries.isEmpty {
                        filteredEmptyState
                    } else {
                        entriesList
                    }
                }
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $vm.selectedFilter) {
            ForEach(WatchHistoryViewModel.MediaFilter.allCases, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }

    private var entriesList: some View {
        List {
            ForEach(vm.groupedEntries, id: \.monthYear) { section in
                Section(section.monthYear) {
                    ForEach(section.entries) { entry in
                        HistoryRow(entry: entry, userId: vm.userId)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.3))
            Text("Nothing watched yet.\nMark items as Watched in My List or Our List.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.3))
            Text("No watched \(vm.selectedFilter == .movie ? "movies" : "TV shows") yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct HistoryRow: View {

    let entry: HistoryEntry
    let userId: String

    var body: some View {
        HStack(spacing: 12) {
            poster
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(2)
                badges
                ratingsRow
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    // MARK: Poster

    private var poster: some View {
        Group {
            if !entry.posterPath.isEmpty, let url = TMDBService.posterURL(entry.posterPath, size: "w92") {
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

    // MARK: Badges

    private var badges: some View {
        HStack(spacing: 6) {
            // Media type
            Text(entry.mediaType == "movie" ? "Movie" : "Series")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.purple.opacity(0.15), in: Capsule())
                .foregroundStyle(.purple)

            // Source list
            Text(entry.source == .myList ? "My List" : "Our List")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (entry.source == .myList ? Color.blue : Color.pink).opacity(0.15),
                    in: Capsule()
                )
                .foregroundStyle(entry.source == .myList ? .blue : .pink)

            // Release year
            if entry.releaseYear > 0 {
                Text(verbatim: "\(entry.releaseYear)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Ratings + date

    private var ratingsRow: some View {
        HStack(spacing: 10) {
            if entry.source == .myList {
                ratingChip(label: nil, rating: entry.myRating)
            } else {
                ratingChip(label: "You", rating: entry.coupleRatings[userId])
                ratingChip(label: "Partner", rating: entry.coupleRatings.first(where: { $0.key != userId })?.value)
            }
            Spacer()
            if let date = entry.watchedAt {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ratingChip(label: String?, rating: Int?) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(rating != nil ? .orange : .secondary.opacity(0.4))
            if let rating {
                Text(label.map { "\($0): \(rating)/10" } ?? "\(rating)/10")
                    .font(.caption)
                    .foregroundStyle(.primary)
            } else {
                Text(label.map { "\($0): —" } ?? "Not rated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

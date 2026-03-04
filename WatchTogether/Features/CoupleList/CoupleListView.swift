import SwiftUI
import Kingfisher

struct CoupleListView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var vm: CoupleListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    CoupleListContentView(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Our List")
        }
        .task {
            guard vm == nil,
                  let coupleId = auth.currentUser?.coupleId,
                  let userId = auth.currentUser?.id else { return }
            let viewModel = CoupleListViewModel(coupleId: coupleId, userId: userId)
            vm = viewModel
            viewModel.startWatching()
        }
    }
}

// MARK: - Content

@MainActor
private struct CoupleListContentView: View {

    @Bindable var vm: CoupleListViewModel

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 0) {
                    statusPicker
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Divider().padding(.top, 8)
                    if vm.filteredItems.isEmpty {
                        emptyState
                    } else {
                        itemsList
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showRatingPicker) {
            if let item = vm.itemToRate {
                RatingPickerView(currentRating: item.ratings[vm.userId]) { rating in
                    Task { await vm.rate(item: item, rating: rating) }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = vm.toastMessage {
                Text(msg)
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.78))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: vm.toastMessage)
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var statusPicker: some View {
        Picker("Status", selection: $vm.selectedStatus) {
            ForEach(WatchlistStatus.allCases, id: \.self) {
                Text($0.label).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }

    private var itemsList: some View {
        List {
            ForEach(vm.filteredItems) { item in
                CoupleWatchlistRow(item: item, vm: vm)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .onDelete { offsets in
                for i in offsets {
                    let item = vm.filteredItems[i]
                    Task { await vm.remove(item: item) }
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 48))
                .foregroundStyle(.purple.opacity(0.3))
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        switch vm.selectedStatus {
        case .want:     "Add movies or shows from the detail page to watch together."
        case .watching: "Move an item here when you start watching it together."
        case .watched:  "Mark items as Watched to see them here."
        }
    }
}

// MARK: - Row

private struct CoupleWatchlistRow: View {

    let item: CoupleWatchlistItem
    let vm: CoupleListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                poster
                info
                Spacer(minLength: 0)
            }
            statusButtons
            if item.status == .watched {
                ratingsRow
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Poster

    private var poster: some View {
        Group {
            if !item.posterPath.isEmpty, let url = TMDBService.posterURL(item.posterPath, size: "w92") {
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

    // MARK: Info

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(item.mediaType == "movie" ? "Movie" : "Series")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.purple.opacity(0.15), in: Capsule())
                    .foregroundStyle(.purple)

                if item.releaseYear > 0 {
                    Text(verbatim: "\(item.releaseYear)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(item.nominatedBy == vm.userId ? "You picked" : "Partner picked")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        (item.nominatedBy == vm.userId ? Color.blue : Color.pink).opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(item.nominatedBy == vm.userId ? .blue : .pink)
            }
        }
    }

    // MARK: Inline status buttons

    private var statusButtons: some View {
        HStack(spacing: 8) {
            ForEach(WatchlistStatus.allCases, id: \.self) { status in
                let isSelected = item.status == status
                Button {
                    Task { await vm.updateStatus(item: item, to: status) }
                } label: {
                    Text(status.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? .purple : .purple.opacity(0.08))
                        .foregroundStyle(isSelected ? .white : .purple)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Ratings (shown only for watched items)

    private var ratingsRow: some View {
        HStack(spacing: 16) {
            ratingChip(label: "You", rating: item.ratings[vm.userId])
            ratingChip(label: "Partner", rating: item.ratings.first(where: { $0.key != vm.userId })?.value)
        }
        .padding(.top, 2)
    }

    private func ratingChip(label: String, rating: Int?) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(rating != nil ? .orange : .secondary.opacity(0.5))
            if let rating {
                Text("\(label): \(rating)/10")
                    .font(.caption)
                    .foregroundStyle(.primary)
            } else {
                Text("\(label): awaiting…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

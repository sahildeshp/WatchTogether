import SwiftUI
import Kingfisher

struct MyListView: View {

    @Environment(AuthViewModel.self) private var auth
    @State private var vm: MyListViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm {
                    MyListContentView(vm: vm)
                } else {
                    ProgressView()
                        .navigationTitle("My List")
                }
            }
        }
        .task {
            guard let userId = auth.currentUser?.id else { return }
            if vm == nil {
                vm = MyListViewModel(userId: userId)
            }
            vm?.startWatching()
        }
    }
}

// MARK: - Content (extracted so @Bindable works cleanly)

@MainActor
private struct MyListContentView: View {

    @Bindable var vm: MyListViewModel

    var body: some View {
        VStack(spacing: 0) {
            statusPicker
            listBody
        }
        .navigationTitle("My List")
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .sheet(isPresented: $vm.showRatingPicker) {
            if let item = vm.itemToRate {
                RatingPickerView(currentRating: item.rating) { rating in
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
    }

    // MARK: - Status picker

    private var statusPicker: some View {
        Picker("Status", selection: $vm.selectedStatus) {
            ForEach(WatchlistStatus.allCases, id: \.self) {
                Text($0.label).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - List body

    @ViewBuilder
    private var listBody: some View {
        if vm.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.filteredItems.isEmpty {
            emptyState
        } else {
            List {
                ForEach(vm.filteredItems) { item in
                    WatchlistRow(item: item, vm: vm)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await vm.remove(item: item) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: vm.selectedStatus.icon)
                .font(.system(size: 44))
                .foregroundStyle(.purple.opacity(0.4))
            Text("Nothing here yet")
                .font(.title3.bold())
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
        case .want:     "Search for movies or shows and tap \"Add to My List\"."
        case .watching: "Tap the Watching button on any item to move it here."
        case .watched:  "Mark items as Watched to see them here."
        }
    }
}

// MARK: - Row

private struct WatchlistRow: View {

    let item: WatchlistItem
    let vm: MyListViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                poster
                info
                Spacer(minLength: 0)
            }
            statusButtons
        }
        .padding(.vertical, 4)
    }

    // MARK: Poster

    private var poster: some View {
        Group {
            if let url = TMDBService.posterURL(item.posterPath) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .overlay { Image(systemName: "film").foregroundStyle(.secondary) }
            }
        }
        .frame(width: 48, height: 72)
        .clipShape(.rect(cornerRadius: 6))
    }

    // MARK: Info

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.subheadline.bold())
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(item.mediaType == "movie" ? "Movie" : "Series")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.purple.opacity(0.1), in: Capsule())
                    .foregroundStyle(.purple)
                if item.releaseYear > 0 {
                    Text(verbatim: "\(item.releaseYear)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let rating = item.rating {
                Label("\(rating)/10", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
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
}

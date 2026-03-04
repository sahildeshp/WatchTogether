import SwiftUI
import Kingfisher

struct ContentDetailView: View {

    let result: TMDBSearchResult
    let service: TMDBService

    @State private var vm: ContentDetailViewModel
    @Environment(AuthViewModel.self) private var auth

    init(result: TMDBSearchResult, service: TMDBService = .shared) {
        self.result = result
        self.service = service
        _vm = State(initialValue: ContentDetailViewModel(result: result, service: service))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail = vm.detail {
                detailScrollView(detail: detail)
            } else if let err = vm.errorMessage {
                errorView(message: err)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if vm.detail != nil { ourListBottomBar }
        }
        .task {
            vm.userId = auth.currentUser?.id
            vm.coupleId = auth.currentUser?.coupleId
            await vm.load()
        }
    }

    // MARK: - Detail scroll view

    private func detailScrollView(detail: TMDBDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection(detail: detail)
                infoSection(detail: detail)
                Divider().padding(.horizontal)
                if !detail.overview.isEmpty {
                    overviewSection(overview: detail.overview)
                    Divider().padding(.horizontal)
                }
                if let credits = detail.credits, !credits.cast.isEmpty {
                    castSection(cast: Array(credits.cast.prefix(10)))
                }
                Spacer(minLength: 16)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Hero (backdrop + floating poster + title)

    private func heroSection(detail: TMDBDetail) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop
            if let path = detail.backdropPath, let url = TMDBService.backdropURL(path) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.25))
                    .frame(height: 240)
            }

            // Gradient so the poster is legible over the image
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .frame(height: 240)

            // Poster + quick metadata (sits at the bottom of the ZStack)
            HStack(alignment: .bottom, spacing: 14) {
                posterImage(path: detail.posterPath)
                    .offset(y: 44)   // bleed below the backdrop

                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.mediaTypeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.purple, in: Capsule())

                    if let year = detail.releaseYear {
                        Text(verbatim: "\(year)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    if let rt = detail.runtimeOrSeasons {
                        Text(rt)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.bottom, 12)
            }
            .padding(.horizontal)
        }
        // Reserve the vertical space the poster bleed takes up
        .padding(.bottom, 44)
    }

    private func posterImage(path: String?) -> some View {
        Group {
            if let path, let url = TMDBService.posterURL(path) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "film")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 88, height: 132)
        .clipShape(.rect(cornerRadius: 10))
        .shadow(radius: 8, y: 4)
    }

    // MARK: - Info (title, genres, director)

    private func infoSection(detail: TMDBDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(detail.title)
                .font(.title2.bold())

            if !detail.genres.isEmpty {
                Text(detail.genres.prefix(3).joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let director = detail.directorOrCreator {
                Label(director, systemImage: "video.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Overview

    private func overviewSection(overview: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.headline)
            Text(overview)
                .font(.body)
                .foregroundStyle(.primary.opacity(0.85))
        }
        .padding()
    }

    // MARK: - Cast

    private func castSection(cast: [TMDBCredits.CastMember]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cast")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(cast) { member in
                        CastCard(member: member)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Pinned bottom bar (two pill buttons)

    private var ourListBottomBar: some View {
        HStack(spacing: 12) {
            // My List pill
            Button {
                Task { await vm.addToMyList() }
            } label: {
                Group {
                    if vm.isAddingToList {
                        ProgressView().tint(.white)
                    } else {
                        Label(vm.myListStatus != nil ? vm.myListStatus!.label : "My List",
                              systemImage: vm.myListStatus != nil ? vm.myListStatus!.icon : "bookmark")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(vm.myListStatus != nil ? .purple : .purple.opacity(0.12))
                .foregroundStyle(vm.myListStatus != nil ? .white : .purple)
                .clipShape(Capsule())
            }
            .disabled(vm.isAddingToList || vm.myListStatus != nil)

            // Our List pill
            Button {
                Task { await vm.addToOurList() }
            } label: {
                Group {
                    if vm.isAddingToCoupleList {
                        ProgressView().tint(.white)
                    } else {
                        Label(vm.coupleListStatus != nil ? vm.coupleListStatus!.label : "Our List",
                              systemImage: vm.coupleListStatus != nil ? vm.coupleListStatus!.icon : "heart")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(vm.coupleListStatus != nil ? .pink : .purple.opacity(0.12))
                .foregroundStyle(vm.coupleListStatus != nil ? .white : .purple)
                .clipShape(Capsule())
            }
            .disabled(vm.isAddingToCoupleList || vm.coupleListStatus != nil || vm.coupleId == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry") { Task { await vm.load() } }
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Cast card

private struct CastCard: View {

    let member: TMDBCredits.CastMember

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let path = member.profilePath, let url = TMDBService.profileURL(path) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle()
                        .fill(.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text(member.name)
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)

            if let character = member.character, !character.isEmpty {
                Text(character)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 70)
            }
        }
    }
}

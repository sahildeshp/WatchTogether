import SwiftUI
import PhotosUI
import Kingfisher
import UIKit

struct ProfileView: View {

    @Environment(AuthViewModel.self) private var auth
    @AppStorage("forceDarkMode") private var forceDarkMode = false
    @State private var showPairingSheet = false
    @State private var showLeaveConfirmation = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                partnerSection
                appearanceSection
                signOutSection
            }
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showPairingSheet) {
            PairingView()
        }
        .onChange(of: auth.currentUser?.coupleId) { _, newValue in
            if newValue != nil { showPairingSheet = false }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await uploadPhoto(item) }
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section("Account") {
            if let user = auth.currentUser {
                HStack(spacing: 14) {
                    // ZStack keeps the badge overlay outside the PhotosPicker label
                    // closure, avoiding Swift 6 main-actor isolation errors.
                    ZStack(alignment: .bottomTrailing) {
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            // Inline avatar — no @MainActor method calls inside the closure.
                            if let url = user.photoURL {
                                KFImage(url)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.purple.opacity(0.6))
                                    .frame(width: 60, height: 60)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change profile photo")

                        // Badge lives outside the closure — can access @MainActor state.
                        if isUploadingPhoto {
                            ProgressView()
                                .tint(.white)
                                .padding(4)
                                .background(.purple, in: Circle())
                                .allowsHitTesting(false)
                        } else {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .background(.white, in: Circle())
                                .allowsHitTesting(false)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName ?? "—")
                            .font(.headline)
                        Text(user.email ?? "—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var partnerSection: some View {
        Section("Partner") {
            if auth.currentUser?.coupleId != nil {
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.pink)
                    if let name = auth.partnerName {
                        Text("Connected with \(name)")
                    } else {
                        Text("Connected with your partner")
                    }
                }
                .accessibilityElement(children: .combine)
                Button("Leave Couple", role: .destructive) {
                    showLeaveConfirmation = true
                }
                .confirmationDialog(
                    "Leave Couple?",
                    isPresented: $showLeaveConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Leave Couple", role: .destructive) {
                        Task { await auth.leaveCouple() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Your shared watchlist will remain, but you'll no longer be paired. Your partner will still be connected until they also leave.")
                }
            } else {
                Button {
                    showPairingSheet = true
                } label: {
                    Label("Add Partner", systemImage: "person.badge.plus")
                        .foregroundStyle(.purple)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(isOn: $forceDarkMode) {
                Label("Dark Mode", systemImage: "moon.fill")
            }
            .tint(.purple)
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign Out", role: .destructive) { auth.signOut() }
        }
    }

    // MARK: - Helpers

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        // Load raw bytes from the picker (may be HEIC on device), then transcode
        // to JPEG so the uploaded bytes are always in a displayable format.
        guard
            let rawData = try? await item.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: rawData),
            let jpegData = uiImage.jpegData(compressionQuality: 0.8)
        else { return }

        isUploadingPhoto = true
        await auth.uploadProfilePhoto(jpegData)
        isUploadingPhoto = false
        selectedPhoto = nil
    }
}

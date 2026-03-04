import SwiftUI

struct ProfileView: View {

    @Environment(AuthViewModel.self) private var auth
    @AppStorage("forceDarkMode") private var forceDarkMode = false
    @State private var showPairingSheet = false
    @State private var showLeaveConfirmation = false

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
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section("Account") {
            if let user = auth.currentUser {
                LabeledContent("Name", value: user.displayName ?? "—")
                LabeledContent("Email", value: user.email ?? "—")
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
}

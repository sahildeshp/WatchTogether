import SwiftUI

/// The app's root view. Observes auth state and routes to the correct screen.
///
///  ┌─ isLoading ──► Splash
///  ├─ signed out ──► AuthView  (login / register)
///  ├─ signed in, no couple ──► PairingPlaceholder  (Phase 3)
///  └─ signed in, has couple ──► MainTabPlaceholder  (Phase 4)
struct RootView: View {

    @State private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.isLoading {
                splash
            } else if auth.currentUser == nil {
                AuthView()
            } else if auth.currentUser?.coupleId == nil {
                pairingPlaceholder
            } else {
                mainPlaceholder
            }
        }
        .environment(auth)
        .animation(.easeInOut(duration: 0.25), value: auth.currentUser?.id)
        .animation(.easeInOut(duration: 0.25), value: auth.isLoading)
    }

    // MARK: - Placeholder screens (replaced in later phases)

    private var splash: some View {
        VStack(spacing: 16) {
            Image(systemName: "popcorn.fill")
                .font(.system(size: 72))
                .foregroundStyle(.purple)
            Text("WatchTogether")
                .font(.largeTitle.bold())
        }
    }

    private var pairingPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.purple)
            Text("Set up your couple account")
                .font(.title2.bold())
            Text("Phase 3 — coming next")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Sign Out", role: .destructive) { auth.signOut() }
                .padding(.top, 8)
        }
        .padding()
    }

    private var mainPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            if let name = auth.currentUser?.displayName {
                Text("Welcome, \(name)!")
                    .font(.title2.bold())
            }
            Text("Phase 4 — main app coming next")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Sign Out", role: .destructive) { auth.signOut() }
                .padding(.top, 8)
        }
        .padding()
    }
}

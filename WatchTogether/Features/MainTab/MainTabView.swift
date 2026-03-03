import SwiftUI

/// Root tab view shown to paired users.
/// Search is functional from Phase 4. Other tabs are activated in later phases.
struct MainTabView: View {

    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            ComingSoonTabView(title: "My List", icon: "list.bullet.rectangle")
                .tabItem { Label("My List", systemImage: "list.bullet.rectangle") }

            ComingSoonTabView(title: "Our List", icon: "heart.fill")
                .tabItem { Label("Our List", systemImage: "heart.fill") }

            ComingSoonTabView(title: "History", icon: "clock.fill")
                .tabItem { Label("History", systemImage: "clock.fill") }

            profileTab
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.purple)
    }

    // MARK: - Profile tab (simple for now; expanded in Phase 8)

    private var profileTab: some View {
        NavigationStack {
            List {
                if let user = auth.currentUser {
                    Section("Account") {
                        LabeledContent("Name", value: user.displayName ?? "—")
                        LabeledContent("Email", value: user.email ?? "—")
                    }
                }
                Section {
                    Button("Sign Out", role: .destructive) { auth.signOut() }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Placeholder for upcoming tabs

private struct ComingSoonTabView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.purple.opacity(0.4))
            Text(title)
                .font(.title3.bold())
            Text("Coming soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

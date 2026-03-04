import SwiftUI

/// Root tab view shown to all signed-in users (paired or unpaired).
struct MainTabView: View {

    var body: some View {
        TabView {
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            MyListView()
                .tabItem { Label("My List", systemImage: "list.bullet.rectangle") }

            CoupleListView()
                .tabItem { Label("Our List", systemImage: "heart.fill") }

            WatchHistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(.purple)
    }
}

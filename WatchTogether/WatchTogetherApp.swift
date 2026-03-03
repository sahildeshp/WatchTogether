import SwiftUI
import SwiftData
import Firebase

@main
struct WatchTogetherApp: App {

    let modelContainer: ModelContainer

    init() {
        // Configure Firebase — requires GoogleService-Info.plist in the bundle.
        // Download it from your Firebase Console → Project Settings → iOS app.
        FirebaseApp.configure()

        do {
            modelContainer = try ModelContainer(
                for: LocalWatchlistItem.self, LocalCouple.self
            )
        } catch {
            fatalError("Failed to initialize SwiftData model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}

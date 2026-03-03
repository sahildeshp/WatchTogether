import SwiftUI

/// The app's root view. Observes auth state and routes to the correct screen.
///
///  ┌─ isLoading ──► Splash
///  ├─ signed out ──► AuthView  (login / register)
///  ├─ signed in, no couple ──► PairingView
///  └─ signed in, has couple ──► MainTabView
struct RootView: View {

    @State private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.isLoading {
                splash
            } else if auth.currentUser == nil {
                AuthView()
            } else if auth.currentUser?.coupleId == nil {
                PairingView()
            } else {
                MainTabView()
            }
        }
        .environment(auth)
        .animation(.easeInOut(duration: 0.25), value: auth.currentUser?.id)
        .animation(.easeInOut(duration: 0.25), value: auth.isLoading)
        .animation(.easeInOut(duration: 0.25), value: auth.currentUser?.coupleId)
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


}

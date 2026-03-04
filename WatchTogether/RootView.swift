import SwiftUI

/// The app's root view. Observes auth state and routes to the correct screen.
///
///  ┌─ isLoading ──► Splash
///  ├─ signed out ──► AuthView  (login / register)
///  └─ signed in  ──► MainTabView  (with or without a partner)
struct RootView: View {

    @State private var auth = AuthViewModel()
    @AppStorage("forceDarkMode") private var forceDarkMode = false

    var body: some View {
        Group {
            if auth.isLoading {
                splash
            } else if auth.currentUser == nil {
                AuthView()
            } else {
                MainTabView()
            }
        }
        .environment(auth)
        .preferredColorScheme(forceDarkMode ? .dark : nil)
        .animation(.easeInOut(duration: 0.25), value: auth.currentUser?.id)
        .animation(.easeInOut(duration: 0.25), value: auth.isLoading)
    }

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

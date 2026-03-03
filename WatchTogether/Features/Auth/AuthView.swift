import SwiftUI

/// Container that toggles between `LoginView` and `RegisterView`.
struct AuthView: View {
    @State private var showLogin = true

    var body: some View {
        Group {
            if showLogin {
                LoginView { withAnimation { showLogin = false } }
            } else {
                RegisterView { withAnimation { showLogin = true } }
            }
        }
        .transition(.opacity)
    }
}

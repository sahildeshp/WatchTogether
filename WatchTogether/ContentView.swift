import SwiftUI

/// Temporary root view for Phase 1 — Foundation.
/// Will be replaced by an auth-state router in Phase 2.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "popcorn.fill")
                .font(.system(size: 72))
                .foregroundStyle(.purple)

            Text("WatchTogether")
                .font(.largeTitle.bold())

            Text("Phase 1 — Foundation ✓")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

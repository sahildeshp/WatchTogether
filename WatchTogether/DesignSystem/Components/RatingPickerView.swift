import SwiftUI

/// A bottom sheet that lets the user pick a rating from 1–10.
struct RatingPickerView: View {

    let title: String
    let currentRating: Int?
    let onSelect: (Int) -> Void

    init(title: String = "Rate this", currentRating: Int?, onSelect: @escaping (Int) -> Void) {
        self.title = title
        self.currentRating = currentRating
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)
                .padding(.top, 20)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                spacing: 12
            ) {
                ForEach(1...10, id: \.self) { n in
                    Button { onSelect(n) } label: {
                        Text("\(n)")
                            .font(.title3.bold())
                            .frame(width: 56, height: 56)
                            .background(currentRating == n ? .purple : .purple.opacity(0.1))
                            .foregroundStyle(currentRating == n ? .white : .purple)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)

            Text("Tap a number to save your rating")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
}

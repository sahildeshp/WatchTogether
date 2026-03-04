import Foundation
@preconcurrency import FirebaseFirestore

/// Firestore-backed implementation of `WatchlistRepository`.
/// Persists items under `users/{userId}/watchlist/{itemId}`.
/// Field names are camelCase, matching Swift property names, because
/// Firestore.Encoder/Decoder don't auto-convert to snake_case.
final class FirestoreWatchlistRepository: WatchlistRepository, @unchecked Sendable {

    private let db = Firestore.firestore()

    private func ref(userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("watchlist")
    }

    // MARK: - Real-time stream

    func watchMyList(userId: String) -> AsyncStream<[WatchlistItem]> {
        AsyncStream { continuation in
            let listener = ref(userId: userId)
                .order(by: "addedAt", descending: true)
                .addSnapshotListener { snapshot, _ in
                    let items = snapshot?.documents.compactMap {
                        try? $0.data(as: WatchlistItem.self)
                    } ?? []
                    continuation.yield(items)
                }
            continuation.onTermination = { @Sendable _ in listener.remove() }
        }
    }

    // MARK: - Writes

    func add(item: WatchlistItem, userId: String) async throws {
        let data = try Firestore.Encoder().encode(item)
        try await ref(userId: userId).document(item.id).setData(data)
    }

    func updateStatus(userId: String, itemId: String, status: WatchlistStatus) async throws {
        var update: [String: Any] = ["status": status.rawValue]
        if status == .watched {
            update["watchedAt"] = FieldValue.serverTimestamp()
        }
        try await ref(userId: userId).document(itemId).updateData(update)
    }

    func updateRating(userId: String, itemId: String, rating: Int) async throws {
        try await ref(userId: userId).document(itemId).updateData(["rating": rating])
    }

    func remove(userId: String, itemId: String) async throws {
        try await ref(userId: userId).document(itemId).delete()
    }
}

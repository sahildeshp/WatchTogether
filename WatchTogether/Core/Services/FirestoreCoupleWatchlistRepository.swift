import Foundation
@preconcurrency import FirebaseFirestore

/// Firestore-backed implementation of `CoupleWatchlistRepository`.
/// Persists items under `couples/{coupleId}/watchlist/{itemId}`.
final class FirestoreCoupleWatchlistRepository: CoupleWatchlistRepository, @unchecked Sendable {

    private let db = Firestore.firestore()

    private func ref(coupleId: String) -> CollectionReference {
        db.collection("couples").document(coupleId).collection("watchlist")
    }

    // MARK: - Real-time stream

    func watchCoupleList(coupleId: String) -> AsyncStream<[CoupleWatchlistItem]> {
        AsyncStream { continuation in
            let listener = ref(coupleId: coupleId)
                .order(by: "addedAt", descending: true)
                .addSnapshotListener { snapshot, _ in
                    let items = snapshot?.documents.compactMap {
                        try? $0.data(as: CoupleWatchlistItem.self)
                    } ?? []
                    continuation.yield(items)
                }
            continuation.onTermination = { @Sendable _ in listener.remove() }
        }
    }

    // MARK: - Writes

    func add(item: CoupleWatchlistItem, coupleId: String) async throws {
        let data = try Firestore.Encoder().encode(item)
        try await ref(coupleId: coupleId).document(item.id).setData(data)
    }

    func updateStatus(coupleId: String, itemId: String, status: WatchlistStatus, watchedBy: String?) async throws {
        var update: [String: Any] = ["status": status.rawValue]
        if status == .watched {
            update["watchedAt"] = FieldValue.serverTimestamp()
            if let watchedBy {
                update["watchedBy"] = watchedBy
            }
        }
        try await ref(coupleId: coupleId).document(itemId).updateData(update)
    }

    func updateRating(coupleId: String, itemId: String, userId: String, rating: Int) async throws {
        try await ref(coupleId: coupleId).document(itemId).updateData(["ratings.\(userId)": rating])
    }

    func remove(coupleId: String, itemId: String) async throws {
        try await ref(coupleId: coupleId).document(itemId).delete()
    }
}

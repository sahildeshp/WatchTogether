import Foundation

/// The signed-in user, combining Firebase Auth identity with Firestore profile data.
struct AppUser: Sendable, Identifiable {
    let id: String          // Firebase Auth UID
    let email: String?
    var displayName: String?
    var photoURL: URL?
    var coupleId: String?   // nil until the user pairs with a partner
}

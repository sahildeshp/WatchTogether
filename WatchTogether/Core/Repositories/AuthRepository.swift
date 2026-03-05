import Foundation

/// Defines the contract for authentication operations.
/// Concrete implementations (e.g. FirebaseAuthRepository) are injected at the call site.
protocol AuthRepository: Sendable {
    /// Emits the current user whenever auth state changes. Yields `nil` when signed out.
    var userStream: AsyncStream<AppUser?> { get }

    func signIn(email: String, password: String) async throws
    func register(email: String, password: String, displayName: String) async throws
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws
    func signOut() throws
    /// Uploads JPEG data to Firebase Storage, updates both Firebase Auth profile and
    /// the Firestore user document, and returns the resulting download URL.
    func uploadProfilePhoto(_ imageData: Data) async throws -> URL
}

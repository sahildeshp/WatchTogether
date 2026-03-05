import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Firebase-backed implementation of `AuthRepository`.
final class FirebaseAuthRepository: AuthRepository, @unchecked Sendable {

    // MARK: - Auth state stream

    var userStream: AsyncStream<AppUser?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, firebaseUser in
                guard let firebaseUser else {
                    continuation.yield(nil)
                    return
                }
                // Extract Sendable values before crossing into the async Task —
                // FirebaseAuth.User is not Sendable in Swift 6.
                let uid = firebaseUser.uid
                let email = firebaseUser.email
                let displayName = firebaseUser.displayName
                let photoURL = firebaseUser.photoURL
                Task {
                    let user = await Self.buildAppUser(
                        uid: uid, email: email,
                        displayName: displayName, authPhotoURL: photoURL
                    )
                    continuation.yield(user)
                }
            }
            // NSObjectProtocol is not Sendable; box it so the @Sendable closure can capture it.
            let box = HandleBox(handle)
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(box.value)
            }
        }
    }

    // MARK: - Sign in / out

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
        // auth state listener fires automatically → userStream emits the new user
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Registration

    func register(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Update the Firebase Auth display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        // Create the Firestore user document
        try await Firestore.firestore()
            .collection("users")
            .document(result.user.uid)
            .setData([
                "displayName": displayName,
                "email": email,
                "coupleId": NSNull(),
                "createdAt": FieldValue.serverTimestamp()
            ])
    }

    // MARK: - Apple Sign-In

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce
        )
        let result = try await Auth.auth().signIn(with: credential)

        // Apple only provides fullName on the very first sign-in
        if let fullName, fullName.givenName != nil || fullName.familyName != nil {
            let formatted = PersonNameComponentsFormatter().string(from: fullName)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = formatted
            try await changeRequest.commitChanges()
        }

        // Create Firestore doc only on first sign-in
        let userRef = Firestore.firestore().collection("users").document(result.user.uid)
        let doc = try await userRef.getDocument()
        guard !doc.exists else { return }

        try await userRef.setData([
            "displayName": result.user.displayName ?? "User",
            "email": result.user.email as Any,
            "coupleId": NSNull(),
            "createdAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Profile photo upload

    func uploadProfilePhoto(_ imageData: Data) async throws -> URL {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw AuthError.message("Not signed in.")
        }
        let ref = Storage.storage().reference().child("profile_photos/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        // Persist in Firestore so all clients can read it.
        // We intentionally skip updating the Firebase Auth profile (commitChanges)
        // because that triggers stateDidChangeListener → buildAppUser, which would
        // race against the currentUser?.photoURL update already applied in AuthViewModel.
        try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .updateData(["photoURL": downloadURL.absoluteString])

        return downloadURL
    }

    // MARK: - Helpers

    /// Builds an `AppUser` by merging Firebase Auth values with Firestore profile data.
    /// `photoURL` is preferred from Firestore (updated by `uploadProfilePhoto`) and falls
    /// back to the Firebase Auth value when absent.
    private static func buildAppUser(
        uid: String,
        email: String?,
        displayName: String?,
        authPhotoURL: URL?
    ) async -> AppUser {
        do {
            let doc = try await Firestore.firestore()
                .collection("users")
                .document(uid)
                .getDocument()
            let data = doc.data()
            let coupleId = data?["coupleId"] as? String
            // Prefer Firestore-stored URL (set by our upload flow)
            let photoURL: URL?
            if let urlString = data?["photoURL"] as? String {
                photoURL = URL(string: urlString)
            } else {
                photoURL = authPhotoURL
            }
            return AppUser(id: uid, email: email, displayName: displayName, photoURL: photoURL, coupleId: coupleId)
        } catch {
            // Return user without coupleId / photo if Firestore is unavailable (offline)
            return AppUser(id: uid, email: email, displayName: displayName, photoURL: authPhotoURL, coupleId: nil)
        }
    }
}

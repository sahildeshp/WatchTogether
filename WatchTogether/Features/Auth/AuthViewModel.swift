import Foundation

// MARK: - Error type

enum AuthError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        if case .message(let msg) = self { return msg }
        return nil
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class AuthViewModel {

    // MARK: Published state

    /// The currently signed-in user, or `nil` when signed out.
    private(set) var currentUser: AppUser?
    /// `true` until the first auth-state event is received from Firebase.
    private(set) var isLoading = true
    /// Set when a sign-in / register / sign-out operation fails.
    var error: AuthError?
    /// Display name of the partner, populated when the user is paired.
    private(set) var partnerName: String?

    // MARK: Private

    private let repository: AuthRepository
    private let coupleRepository: CoupleRepository

    /// The task that drives the auth-state observation loop.
    /// Stored as `nonisolated(unsafe)` so it can be cancelled from `deinit`.
    nonisolated(unsafe) private var observationTask: Task<Void, Never>?

    // MARK: Init / deinit

    init(
        repository: AuthRepository = FirebaseAuthRepository(),
        coupleRepository: CoupleRepository = FirebaseCoupleRepository()
    ) {
        self.repository = repository
        self.coupleRepository = coupleRepository
        observationTask = Task {
            for await user in repository.userStream {
                self.currentUser = user
                self.isLoading = false
                if let user {
                    // Register for push notifications and save FCM token
                    await NotificationService.shared.setup(userId: user.id)
                    // Fetch partner name if paired
                    await self.refreshPartnerName(for: user)
                } else {
                    self.partnerName = nil
                }
            }
        }
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: - Auth actions

    func signIn(email: String, password: String) async {
        error = nil
        isLoading = true
        do {
            try await repository.signIn(email: email, password: password)
            // isLoading set to false by the userStream observer
        } catch {
            self.error = .message(error.localizedDescription)
            isLoading = false
        }
    }

    func register(email: String, password: String, displayName: String) async {
        error = nil
        isLoading = true
        do {
            try await repository.register(email: email, password: password, displayName: displayName)
        } catch {
            self.error = .message(error.localizedDescription)
            isLoading = false
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async {
        error = nil
        isLoading = true
        do {
            try await repository.signInWithApple(idToken: idToken, rawNonce: rawNonce, fullName: fullName)
        } catch {
            self.error = .message(error.localizedDescription)
            isLoading = false
        }
    }

    func signOut() {
        error = nil
        do {
            try repository.signOut()
        } catch {
            self.error = .message(error.localizedDescription)
        }
    }

    // MARK: - Profile photo

    func uploadProfilePhoto(_ imageData: Data) async {
        error = nil
        do {
            let url = try await repository.uploadProfilePhoto(imageData)
            currentUser?.photoURL = url
        } catch {
            self.error = .message(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    func clearError() {
        error = nil
    }

    /// Called by PairingViewModel after a successful couple creation or join.
    /// Patches the in-memory user so RootView transitions immediately, without
    /// waiting for the next Firebase auth-state event.
    func updateCoupleId(_ coupleId: String) {
        guard var user = currentUser else { return }
        user.coupleId = coupleId
        currentUser = user
        Task { await refreshPartnerName(for: user) }
    }

    /// Removes the user from their couple in Firestore and clears it in memory.
    func leaveCouple() async {
        guard let user = currentUser, user.coupleId != nil else { return }
        do {
            try await coupleRepository.leaveCouple(userId: user.id)
            var updated = user
            updated.coupleId = nil
            currentUser = updated
            partnerName = nil
        } catch {
            self.error = .message(error.localizedDescription)
        }
    }

    // MARK: - Private helpers

    private func refreshPartnerName(for user: AppUser) async {
        guard let coupleId = user.coupleId else {
            partnerName = nil
            return
        }
        partnerName = await coupleRepository.fetchPartnerName(coupleId: coupleId, userId: user.id)
    }
}

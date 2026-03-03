import Foundation

@MainActor
@Observable
final class PairingViewModel {

    // MARK: - Step

    enum Step: Equatable {
        case chooser
        case creating
        case created(inviteCode: String, coupleId: String)
        case joining
        case joiningLoading
    }

    // MARK: - State

    private(set) var step: Step = .chooser
    var inviteCodeInput: String = ""
    var errorMessage: String?

    // MARK: - Dependencies

    private let repository: CoupleRepository
    /// Unowned because AuthViewModel lives for the entire app session (created
    /// as @State in RootView and never deallocated while the app is running).
    private unowned let authViewModel: AuthViewModel

    // MARK: - Init

    init(authViewModel: AuthViewModel,
         repository: CoupleRepository = FirebaseCoupleRepository()) {
        self.authViewModel = authViewModel
        self.repository = repository
    }

    // MARK: - Create flow

    func startCreateCouple() async {
        step = .creating
        errorMessage = nil
        do {
            let info = try await repository.createCouple()
            // Show the invite code — user taps "Done" to transition to the main app
            step = .created(inviteCode: info.inviteCode ?? "", coupleId: info.coupleId)
        } catch {
            errorMessage = error.localizedDescription
            step = .chooser
        }
    }

    /// Called when the user taps "I've shared the code — continue".
    /// Updating coupleId on AuthViewModel causes RootView to transition to main.
    func finishCreation(coupleId: String) {
        authViewModel.updateCoupleId(coupleId)
    }

    // MARK: - Join flow

    func startJoinFlow() {
        step = .joining
        inviteCodeInput = ""
        errorMessage = nil
    }

    func submitJoinCode() async {
        let code = inviteCodeInput.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty else {
            errorMessage = "Please enter the invite code."
            return
        }
        step = .joiningLoading
        errorMessage = nil
        do {
            let info = try await repository.joinCouple(inviteCode: code)
            // Immediately transition to the main app
            authViewModel.updateCoupleId(info.coupleId)
        } catch {
            errorMessage = error.localizedDescription
            step = .joining
        }
    }

    func cancelJoin() {
        step = .chooser
        inviteCodeInput = ""
        errorMessage = nil
    }

    // MARK: - Deep link

    func handleDeepLink(code: String) {
        inviteCodeInput = code
        step = .joining
        Task { await submitJoinCode() }
    }
}

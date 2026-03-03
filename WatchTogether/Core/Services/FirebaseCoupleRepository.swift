import Foundation
import FirebaseFunctions

/// Firebase Cloud Functions–backed implementation of `CoupleRepository`.
/// The Firebase SDK automatically attaches the signed-in user's auth token to
/// each call, so the Cloud Functions can trust `request.auth.uid` server-side.
final class FirebaseCoupleRepository: CoupleRepository, @unchecked Sendable {

    private let functions = Functions.functions()

    func createCouple() async throws -> CoupleInfo {
        let result = try await functions.httpsCallable("createCouple").call()
        guard
            let data = result.data as? [String: Any],
            let coupleId = data["coupleId"] as? String,
            let inviteCode = data["inviteCode"] as? String
        else {
            throw CoupleError.invalidResponse
        }
        return CoupleInfo(coupleId: coupleId, inviteCode: inviteCode)
    }

    func joinCouple(inviteCode: String) async throws -> CoupleInfo {
        let result = try await functions.httpsCallable("joinCouple").call(["inviteCode": inviteCode])
        guard
            let data = result.data as? [String: Any],
            let coupleId = data["coupleId"] as? String
        else {
            throw CoupleError.invalidResponse
        }
        return CoupleInfo(coupleId: coupleId, inviteCode: nil)
    }
}

// MARK: - Error

enum CoupleError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Unexpected server response. Please try again."
    }
}

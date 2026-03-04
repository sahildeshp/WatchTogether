import Foundation

/// Result returned by both pairing operations.
struct CoupleInfo: Sendable {
    let coupleId: String
    /// Present after `createCouple`; `nil` after `joinCouple` (code is single-use).
    let inviteCode: String?
}

/// Abstraction over the couple-pairing service (Cloud Functions).
protocol CoupleRepository: Sendable {
    /// Creates a new couple for the signed-in user and returns an invite code.
    func createCouple() async throws -> CoupleInfo
    /// Joins an existing couple using a partner's invite code.
    func joinCouple(inviteCode: String) async throws -> CoupleInfo
    /// Removes the signed-in user from their current couple (clears coupleId on their user doc).
    func leaveCouple(userId: String) async throws
    /// Fetches the display name of the other member of the couple.
    func fetchPartnerName(coupleId: String, userId: String) async -> String?
}

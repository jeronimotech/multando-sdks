import Foundation

/// Full profile of the authenticated user.
public struct UserProfile: Codable, Sendable {
    public let id: String
    public let email: String
    public let fullName: String
    public let walletAddress: String?
    public let reputationScore: Double
    public let totalReports: Int
    public let verifiedReports: Int
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case walletAddress = "wallet_address"
        case reputationScore = "reputation_score"
        case totalReports = "total_reports"
        case verifiedReports = "verified_reports"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Public-facing user information (e.g. shown on reports).
public struct UserPublic: Codable, Sendable {
    public let id: String
    public let fullName: String
    public let reputationScore: Double

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case reputationScore = "reputation_score"
    }
}

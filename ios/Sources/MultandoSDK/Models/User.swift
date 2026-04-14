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

    /// Lifetime count of reports submitted by this user. Mirrors
    /// `totalReports` but matches the backend's `total_reports_count` field
    /// added alongside rejection tracking.
    public let totalReportsCount: Int
    /// Number of reports that have been rejected. `nil` when the backend
    /// has not computed it yet (e.g. brand-new account).
    public let rejectedReportsCount: Int?
    /// Ratio in `[0, 1]` of rejected reports over total. `nil` when not
    /// enough reports exist to compute a meaningful value.
    public let rejectionRate: Double?
    /// `true` when the rejection rate is above the threshold (currently
    /// 30%) — the UI should surface a guidance banner in that case.
    public let rejectionRateWarning: Bool

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
        case totalReportsCount = "total_reports_count"
        case rejectedReportsCount = "rejected_reports_count"
        case rejectionRate = "rejection_rate"
        case rejectionRateWarning = "rejection_rate_warning"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.email = try c.decode(String.self, forKey: .email)
        self.fullName = try c.decode(String.self, forKey: .fullName)
        self.walletAddress = try c.decodeIfPresent(String.self, forKey: .walletAddress)
        self.reputationScore = try c.decode(Double.self, forKey: .reputationScore)
        self.totalReports = try c.decode(Int.self, forKey: .totalReports)
        self.verifiedReports = try c.decode(Int.self, forKey: .verifiedReports)
        self.createdAt = try c.decode(String.self, forKey: .createdAt)
        self.updatedAt = try c.decode(String.self, forKey: .updatedAt)
        // New fields default sensibly for older backend responses.
        self.totalReportsCount = try c.decodeIfPresent(Int.self, forKey: .totalReportsCount)
            ?? self.totalReports
        self.rejectedReportsCount = try c.decodeIfPresent(Int.self, forKey: .rejectedReportsCount)
        self.rejectionRate = try c.decodeIfPresent(Double.self, forKey: .rejectionRate)
        self.rejectionRateWarning = try c.decodeIfPresent(Bool.self, forKey: .rejectionRateWarning)
            ?? false
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

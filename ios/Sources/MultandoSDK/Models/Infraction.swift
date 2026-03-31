import Foundation

/// Severity classification for an infraction.
public enum InfractionSeverity: String, Codable, Sendable {
    case low
    case medium
    case high
    case critical
}

/// Category grouping for infractions.
public struct InfractionCategory: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
}

/// An infraction type returned by the API.
public struct InfractionResponse: Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let severity: InfractionSeverity
    public let category: InfractionCategory?
    public let fineAmount: Double?
    public let points: Int?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case severity
        case category
        case fineAmount = "fine_amount"
        case points
        case createdAt = "created_at"
    }
}

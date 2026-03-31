import Foundation

/// Vehicle type returned by the API.
public struct VehicleTypeResponse: Codable, Sendable {
    public let id: String
    public let name: String
    public let category: VehicleCategory
    public let description: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case createdAt = "created_at"
    }
}

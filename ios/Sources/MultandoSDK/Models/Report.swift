import Foundation

/// GPS coordinates associated with a report.
public struct LocationData: Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let address: String?
    public let city: String?
    public let state: String?
    public let country: String?

    public init(latitude: Double, longitude: Double, address: String? = nil, city: String? = nil, state: String? = nil, country: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
        self.state = state
        self.country = country
    }
}

/// Payload for creating a new report.
public struct ReportCreate: Codable, Sendable {
    public let infractionId: String
    public let vehicleTypeId: String
    public let licensePlate: String?
    public let description: String
    public let location: LocationData
    public let occurredAt: String
    public let source: ReportSource

    public init(
        infractionId: String,
        vehicleTypeId: String,
        licensePlate: String? = nil,
        description: String,
        location: LocationData,
        occurredAt: String,
        source: ReportSource = .sdk
    ) {
        self.infractionId = infractionId
        self.vehicleTypeId = vehicleTypeId
        self.licensePlate = licensePlate
        self.description = description
        self.location = location
        self.occurredAt = occurredAt
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case infractionId = "infraction_id"
        case vehicleTypeId = "vehicle_type_id"
        case licensePlate = "license_plate"
        case description
        case location
        case occurredAt = "occurred_at"
        case source
    }
}

/// Full report details.
public struct ReportDetail: Codable, Sendable {
    public let id: String
    public let userId: String
    public let infractionId: String
    public let vehicleTypeId: String
    public let licensePlate: String?
    public let description: String
    public let location: LocationData
    public let occurredAt: String
    public let status: ReportStatus
    public let source: ReportSource
    public let evidence: [EvidenceResponse]?
    public let createdAt: String
    public let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case infractionId = "infraction_id"
        case vehicleTypeId = "vehicle_type_id"
        case licensePlate = "license_plate"
        case description
        case location
        case occurredAt = "occurred_at"
        case status
        case source
        case evidence
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Lightweight report summary used in list views.
public struct ReportSummary: Codable, Sendable {
    public let id: String
    public let description: String
    public let status: ReportStatus
    public let location: LocationData
    public let occurredAt: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case description
        case status
        case location
        case occurredAt = "occurred_at"
        case createdAt = "created_at"
    }
}

/// Paginated list of report summaries.
public struct ReportList: Codable, Sendable {
    public let items: [ReportSummary]
    public let total: Int
    public let page: Int
    public let pageSize: Int
    public let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case pageSize = "page_size"
        case totalPages = "total_pages"
    }
}

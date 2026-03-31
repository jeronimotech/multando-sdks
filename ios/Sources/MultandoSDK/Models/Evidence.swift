import Foundation

/// Payload for attaching evidence to a report.
public struct EvidenceCreate: Codable, Sendable {
    public let reportId: String
    public let evidenceType: EvidenceType
    public let fileUrl: String
    public let description: String?

    public init(reportId: String, evidenceType: EvidenceType, fileUrl: String, description: String? = nil) {
        self.reportId = reportId
        self.evidenceType = evidenceType
        self.fileUrl = fileUrl
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case reportId = "report_id"
        case evidenceType = "evidence_type"
        case fileUrl = "file_url"
        case description
    }
}

/// Evidence record returned by the API.
public struct EvidenceResponse: Codable, Sendable {
    public let id: String
    public let reportId: String
    public let evidenceType: EvidenceType
    public let fileUrl: String
    public let description: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case reportId = "report_id"
        case evidenceType = "evidence_type"
        case fileUrl = "file_url"
        case description
        case createdAt = "created_at"
    }
}

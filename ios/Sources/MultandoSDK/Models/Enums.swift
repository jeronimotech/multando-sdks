import Foundation

/// Status of a traffic violation report.
public enum ReportStatus: String, Codable, Sendable {
    case pending
    case underReview = "under_review"
    case verified
    case rejected
    case appealed
    case resolved
}

/// Source that originated a report.
public enum ReportSource: String, Codable, Sendable {
    case sdk
    case web
    case mobile
    case api
}

/// High-level vehicle category.
public enum VehicleCategory: String, Codable, Sendable {
    case car
    case motorcycle
    case truck
    case bus
    case bicycle
    case scooter
    case other
}

/// Type of evidence attached to a report.
public enum EvidenceType: String, Codable, Sendable {
    case photo
    case video
    case audio
    case document
}

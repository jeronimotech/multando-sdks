import Foundation

/// Operations for managing evidence attached to reports.
public final class EvidenceService: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Attach evidence to a report.
    public func create(_ evidence: EvidenceCreate) async throws -> EvidenceResponse {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/reports/\(evidence.reportId)/evidence",
            body: evidence
        )
    }

    /// List all evidence for a report.
    public func list(reportId: String) async throws -> [EvidenceResponse] {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/reports/\(reportId)/evidence"
        )
    }

    /// Delete a specific evidence item.
    public func delete(reportId: String, evidenceId: String) async throws {
        try await httpClient.requestVoid(
            method: "DELETE",
            path: "/api/v1/reports/\(reportId)/evidence/\(evidenceId)"
        )
    }
}

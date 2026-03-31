import Foundation

/// Report verification operations (for verifiers/moderators).
public final class VerificationService: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Fetch the queue of reports pending verification.
    public func queue(page: Int = 1, pageSize: Int = 20) async throws -> ReportList {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/verification/queue",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "page_size", value: String(pageSize))
            ]
        )
    }

    /// Verify (approve) a report.
    public func verify(reportId: String, notes: String? = nil) async throws -> ReportDetail {
        var body: [String: String]? = nil
        if let notes {
            body = ["notes": notes]
        }
        return try await httpClient.request(
            method: "POST",
            path: "/api/v1/verification/\(reportId)/verify",
            body: body
        )
    }

    /// Reject a report.
    public func reject(reportId: String, reason: String) async throws -> ReportDetail {
        let body = ["reason": reason]
        return try await httpClient.request(
            method: "POST",
            path: "/api/v1/verification/\(reportId)/reject",
            body: body
        )
    }
}

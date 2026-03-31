import Foundation

/// CRUD operations on traffic violation reports.
public final class ReportService: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Create a new report.
    public func create(_ report: ReportCreate) async throws -> ReportDetail {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/reports",
            body: report
        )
    }

    /// Fetch a paginated list of reports.
    public func list(page: Int = 1, pageSize: Int = 20, status: ReportStatus? = nil) async throws -> ReportList {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize))
        ]
        if let status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }
        return try await httpClient.request(
            method: "GET",
            path: "/api/v1/reports",
            queryItems: queryItems
        )
    }

    /// Fetch a single report by ID.
    public func get(id: String) async throws -> ReportDetail {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/reports/\(id)"
        )
    }

    /// Update an existing report.
    public func update(id: String, report: ReportCreate) async throws -> ReportDetail {
        try await httpClient.request(
            method: "PUT",
            path: "/api/v1/reports/\(id)",
            body: report
        )
    }

    /// Delete a report.
    public func delete(id: String) async throws {
        try await httpClient.requestVoid(
            method: "DELETE",
            path: "/api/v1/reports/\(id)"
        )
    }
}

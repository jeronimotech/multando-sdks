import Foundation

/// Fetches and caches infraction types.
public final class InfractionService: @unchecked Sendable {

    private let httpClient: HTTPClient
    private var cache: [InfractionResponse]?
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    private let lock = NSLock()

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// List all available infraction types. Results are cached for 5 minutes.
    public func list(forceRefresh: Bool = false) async throws -> [InfractionResponse] {
        if !forceRefresh, let cached = cachedValue() {
            return cached
        }

        let infractions: [InfractionResponse] = try await httpClient.request(
            method: "GET",
            path: "/api/v1/infractions"
        )

        lock.lock()
        cache = infractions
        cacheTimestamp = Date()
        lock.unlock()

        return infractions
    }

    /// Fetch a single infraction by ID.
    public func get(id: String) async throws -> InfractionResponse {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/infractions/\(id)"
        )
    }

    /// Clear the in-memory cache.
    public func clearCache() {
        lock.lock()
        cache = nil
        cacheTimestamp = nil
        lock.unlock()
    }

    private func cachedValue() -> [InfractionResponse]? {
        lock.lock()
        defer { lock.unlock() }
        guard let cache, let ts = cacheTimestamp, Date().timeIntervalSince(ts) < cacheTTL else {
            return nil
        }
        return cache
    }
}

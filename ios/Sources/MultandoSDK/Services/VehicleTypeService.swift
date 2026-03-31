import Foundation

/// Fetches and caches vehicle types.
public final class VehicleTypeService: @unchecked Sendable {

    private let httpClient: HTTPClient
    private var cache: [VehicleTypeResponse]?
    private var cacheTimestamp: Date?
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    private let lock = NSLock()

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// List all vehicle types. Results are cached for 5 minutes.
    public func list(forceRefresh: Bool = false) async throws -> [VehicleTypeResponse] {
        if !forceRefresh, let cached = cachedValue() {
            return cached
        }

        let types: [VehicleTypeResponse] = try await httpClient.request(
            method: "GET",
            path: "/api/v1/vehicle-types"
        )

        lock.lock()
        cache = types
        cacheTimestamp = Date()
        lock.unlock()

        return types
    }

    /// Fetch a single vehicle type by ID.
    public func get(id: String) async throws -> VehicleTypeResponse {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/vehicle-types/\(id)"
        )
    }

    /// Clear the in-memory cache.
    public func clearCache() {
        lock.lock()
        cache = nil
        cacheTimestamp = nil
        lock.unlock()
    }

    private func cachedValue() -> [VehicleTypeResponse]? {
        lock.lock()
        defer { lock.unlock() }
        guard let cache, let ts = cacheTimestamp, Date().timeIntervalSince(ts) < cacheTTL else {
            return nil
        }
        return cache
    }
}

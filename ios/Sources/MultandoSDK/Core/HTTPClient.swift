import Foundation

/// Async HTTP client backed by URLSession with automatic auth header injection,
/// 401 token refresh, and snake_case JSON coding.
public final class HTTPClient: @unchecked Sendable {

    // MARK: - Properties

    private let session: URLSession
    private let config: MultandoConfig
    private let authManager: AuthManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Lock used to coalesce concurrent 401 refresh attempts.
    private let refreshLock = NSLock()
    private var isRefreshing = false

    // MARK: - Init

    init(config: MultandoConfig, authManager: AuthManager) {
        self.config = config
        self.authManager = authManager

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        self.session = URLSession(configuration: sessionConfig)

        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    // MARK: - Public API

    func request<T: Decodable>(
        method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try await raw(method: method, path: path, body: body, queryItems: queryItems, authenticated: authenticated)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MultandoError.decodingError(error)
        }
    }

    func requestVoid(
        method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws {
        _ = try await raw(method: method, path: path, body: body, queryItems: queryItems, authenticated: authenticated)
    }

    // MARK: - Internal

    private func raw(
        method: String,
        path: String,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?,
        authenticated: Bool,
        isRetry: Bool = false
    ) async throws -> Data {
        var urlRequest = try buildRequest(method: method, path: path, body: body, queryItems: queryItems, authenticated: authenticated)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw MultandoError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MultandoError.networkError(URLError(.badServerResponse))
        }

        // 401 → attempt token refresh once
        if httpResponse.statusCode == 401 && authenticated && !isRetry {
            try await refreshToken()
            return try await raw(method: method, path: path, body: body, queryItems: queryItems, authenticated: authenticated, isRetry: true)
        }

        // 429 → try to decode the backend's structured rate-limit body.
        if httpResponse.statusCode == 429 {
            if let typed = Self.decodeRateLimitError(data: data, response: httpResponse, body: body) {
                throw typed
            }
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MultandoError.apiError(statusCode: httpResponse.statusCode, message: message)
        }

        return data
    }

    // MARK: - Rate-limit decoding

    /// FastAPI wraps HTTPException(detail=...) as `{"detail": {...}}`.
    private struct RateLimitEnvelope: Decodable {
        let detail: RateLimitDetail
    }

    private struct RateLimitDetail: Decodable {
        let error: String?
        let limit: String?
        let retryAfterSeconds: Int?
        let windowSeconds: Int?

        enum CodingKeys: String, CodingKey {
            case error
            case limit
            case retryAfterSeconds = "retry_after_seconds"
            case windowSeconds = "window_seconds"
        }
    }

    /// Maps a 429 response body + headers onto our typed error cases.
    /// Returns `nil` when the payload doesn't match the known schema so the
    /// caller falls back to a generic ``MultandoError.apiError``.
    private static func decodeRateLimitError(
        data: Data,
        response: HTTPURLResponse,
        body: (any Encodable)?
    ) -> MultandoError? {
        let dec = JSONDecoder()
        let detail: RateLimitDetail?
        if let envelope = try? dec.decode(RateLimitEnvelope.self, from: data) {
            detail = envelope.detail
        } else if let flat = try? dec.decode(RateLimitDetail.self, from: data) {
            detail = flat
        } else {
            detail = nil
        }

        // Retry-After header takes precedence; fall back to the body.
        let headerRetry = response.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
        let retryAfter = TimeInterval(headerRetry ?? detail?.retryAfterSeconds ?? 0)

        switch detail?.limit {
        case "reports_per_hour":
            return .rateLimitExceeded(retryAfter: retryAfter, scope: .hour)
        case "reports_per_day":
            return .rateLimitExceeded(retryAfter: retryAfter, scope: .day)
        case "same_plate_per_user_24h", "plate_reports_24h":
            let plate = Self.extractPlate(from: body) ?? ""
            let hours = max(1, Int((detail?.windowSeconds ?? 0) / 3600))
            return .plateCooldown(plate: plate, retryAfterHours: hours)
        default:
            return nil
        }
    }

    /// Best-effort extraction of `license_plate` from an outgoing report body.
    private static func extractPlate(from body: (any Encodable)?) -> String? {
        guard let body else { return nil }
        let enc = JSONEncoder()
        enc.keyEncodingStrategy = .convertToSnakeCase
        guard
            let data = try? enc.encode(AnyEncodable(body)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json["license_plate"] as? String
    }

    private func buildRequest(
        method: String,
        path: String,
        body: (any Encodable)?,
        queryItems: [URLQueryItem]?,
        authenticated: Bool
    ) throws -> URLRequest {
        guard var components = URLComponents(string: "\(config.baseURL)\(path)") else {
            throw MultandoError.validationError("Invalid URL: \(config.baseURL)\(path)")
        }
        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw MultandoError.validationError("Could not construct URL from components")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.locale, forHTTPHeaderField: "Accept-Language")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")

        if authenticated, let token = authManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return request
    }

    private func refreshToken() async throws {
        guard let refreshToken = authManager.refreshToken else {
            throw MultandoError.authError("No refresh token available")
        }

        let body = RefreshRequest(refreshToken: refreshToken)
        let tokenResponse: TokenResponse = try await request(
            method: "POST",
            path: "/api/v1/auth/refresh",
            body: body,
            authenticated: false
        )
        authManager.store(tokens: tokenResponse)
    }
}

// MARK: - AnyEncodable helper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        _encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

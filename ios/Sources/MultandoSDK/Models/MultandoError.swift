import Foundation

/// Scope of a report-rate-limit breach.
public enum RateLimitScope: String, Sendable {
    case hour
    case day
}

/// Errors thrown by the Multando SDK.
public enum MultandoError: LocalizedError, Sendable {

    /// The API returned a non-2xx status code.
    case apiError(statusCode: Int, message: String)

    /// A network-level failure occurred.
    case networkError(Error)

    /// A request was rejected due to invalid input.
    case validationError(String)

    /// An authentication operation failed (e.g. missing or expired tokens).
    case authError(String)

    /// Response data could not be decoded into the expected type.
    case decodingError(Error)

    /// The caller exceeded the hourly or daily report rate limit.
    /// - Parameters:
    ///   - retryAfter: seconds to wait before retrying, from the `Retry-After`
    ///     header (or the `retry_after_seconds` body field).
    ///   - scope: which window was breached (hour / day).
    case rateLimitExceeded(retryAfter: TimeInterval, scope: RateLimitScope)

    /// The caller tried to report a plate that is still within its cooldown
    /// window (either a per-user duplicate or a plate-volume cap).
    case plateCooldown(plate: String, retryAfterHours: Int)

    public var errorDescription: String? {
        switch self {
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .authError(let message):
            return "Auth error: \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .rateLimitExceeded(_, let scope):
            switch scope {
            case .hour:
                return String(localized: "rate_limit_hour", bundle: .module)
            case .day:
                return String(localized: "rate_limit_day", bundle: .module)
            }
        case .plateCooldown:
            return String(localized: "plate_cooldown", bundle: .module)
        }
    }
}

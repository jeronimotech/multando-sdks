import Foundation

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
        }
    }
}

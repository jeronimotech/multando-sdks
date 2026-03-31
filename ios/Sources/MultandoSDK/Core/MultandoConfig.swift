import Foundation

/// Log verbosity levels.
public enum LogLevel: Int, Sendable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
}

/// Configuration for the Multando SDK.
public struct MultandoConfig: Sendable {

    /// Base URL of the Multando API (no trailing slash).
    public let baseURL: String

    /// API key issued to this application.
    public let apiKey: String

    /// Locale sent in the `Accept-Language` header.
    public let locale: String

    /// Request timeout interval in seconds.
    public let timeout: TimeInterval

    /// When `true`, mutating requests made while offline are queued and replayed when connectivity returns.
    public let enableOfflineQueue: Bool

    /// Logging verbosity.
    public let logLevel: LogLevel

    public init(
        baseURL: String,
        apiKey: String,
        locale: String = "en",
        timeout: TimeInterval = 30,
        enableOfflineQueue: Bool = false,
        logLevel: LogLevel = .none
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.locale = locale
        self.timeout = timeout
        self.enableOfflineQueue = enableOfflineQueue
        self.logLevel = logLevel
    }
}

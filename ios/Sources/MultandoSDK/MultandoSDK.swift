import Foundation

/// Multando SDK entry point.
public enum MultandoSDK {

    /// SDK version string.
    public static let version = "1.0.0"

    /// Initializes the SDK with the given configuration and returns a ready-to-use client.
    ///
    /// - Parameter config: The SDK configuration.
    /// - Returns: A fully initialized ``MultandoClient``.
    public static func initialize(config: MultandoConfig) -> MultandoClient {
        MultandoClient(config: config)
    }
}

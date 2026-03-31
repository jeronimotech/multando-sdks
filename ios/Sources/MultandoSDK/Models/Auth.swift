import Foundation

/// Payload for registering a new user.
public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let fullName: String

    public init(email: String, password: String, fullName: String) {
        self.email = email
        self.password = password
        self.fullName = fullName
    }

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName = "full_name"
    }
}

/// Payload for logging in.
public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Token pair returned by authentication endpoints.
public struct TokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String
    public let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

/// Payload for refreshing an access token.
public struct RefreshRequest: Codable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

/// Payload for linking a blockchain wallet.
public struct WalletLinkRequest: Codable, Sendable {
    public let walletAddress: String
    public let signature: String

    public init(walletAddress: String, signature: String) {
        self.walletAddress = walletAddress
        self.signature = signature
    }

    enum CodingKeys: String, CodingKey {
        case walletAddress = "wallet_address"
        case signature
    }
}

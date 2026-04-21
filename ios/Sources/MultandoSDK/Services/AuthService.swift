import Foundation

/// Authentication and user management operations.
public final class AuthService: Sendable {

    private let httpClient: HTTPClient
    private let authManager: AuthManager

    init(httpClient: HTTPClient, authManager: AuthManager) {
        self.httpClient = httpClient
        self.authManager = authManager
    }

    /// Register a new user account.
    @discardableResult
    public func register(_ request: RegisterRequest) async throws -> TokenResponse {
        let response: TokenResponse = try await httpClient.request(
            method: "POST",
            path: "/api/v1/auth/register",
            body: request,
            authenticated: false
        )
        authManager.store(tokens: response)
        return response
    }

    /// Log in with email and password.
    @discardableResult
    public func login(_ request: LoginRequest) async throws -> TokenResponse {
        let response: TokenResponse = try await httpClient.request(
            method: "POST",
            path: "/api/v1/auth/login",
            body: request,
            authenticated: false
        )
        authManager.store(tokens: response)
        return response
    }

    /// Convenience login with email and password strings.
    @discardableResult
    public func login(email: String, password: String) async throws -> TokenResponse {
        try await login(LoginRequest(email: email, password: password))
    }

    /// Log in via a social/OAuth provider (Google, Apple, etc.).
    @discardableResult
    public func socialLogin(provider: String, idToken: String? = nil, code: String? = nil, redirectUri: String? = nil) async throws -> TokenResponse {
        let body = SocialLoginRequest(idToken: idToken, code: code, redirectUri: redirectUri)
        let response: TokenResponse = try await httpClient.request(
            method: "POST",
            path: "/api/v1/auth/oauth/\(provider)",
            body: body,
            authenticated: false
        )
        authManager.store(tokens: response)
        return response
    }

    /// Refresh the current access token.
    @discardableResult
    public func refresh() async throws -> TokenResponse {
        guard let token = authManager.refreshToken else {
            throw MultandoError.authError("No refresh token available")
        }
        let response: TokenResponse = try await httpClient.request(
            method: "POST",
            path: "/api/v1/auth/refresh",
            body: RefreshRequest(refreshToken: token),
            authenticated: false
        )
        authManager.store(tokens: response)
        return response
    }

    /// Fetch the currently authenticated user's profile.
    public func me() async throws -> UserProfile {
        try await httpClient.request(method: "GET", path: "/api/v1/auth/me")
    }

    /// Link a blockchain wallet to the authenticated account.
    public func linkWallet(_ request: WalletLinkRequest) async throws {
        try await httpClient.requestVoid(
            method: "POST",
            path: "/api/v1/auth/link-wallet",
            body: request
        )
    }

    /// Log out by clearing stored tokens.
    public func logout() {
        authManager.clearTokens()
    }
}

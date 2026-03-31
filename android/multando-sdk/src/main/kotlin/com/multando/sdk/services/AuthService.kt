package com.multando.sdk.services

import com.multando.sdk.core.AuthManager
import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.*

/**
 * Authentication and user management operations.
 */
class AuthService internal constructor(
    private val httpClient: HttpClient,
    private val authManager: AuthManager
) {

    /** Register a new user account. */
    suspend fun register(request: RegisterRequest): TokenResponse {
        val response = httpClient.request<TokenResponse>(
            method = "POST",
            path = "/api/v1/auth/register",
            body = request,
            authenticated = false
        )
        authManager.store(response)
        return response
    }

    /** Log in with email and password. */
    suspend fun login(request: LoginRequest): TokenResponse {
        val response = httpClient.request<TokenResponse>(
            method = "POST",
            path = "/api/v1/auth/login",
            body = request,
            authenticated = false
        )
        authManager.store(response)
        return response
    }

    /** Convenience login with email and password strings. */
    suspend fun login(email: String, password: String): TokenResponse =
        login(LoginRequest(email, password))

    /** Refresh the current access token. */
    suspend fun refresh(): TokenResponse {
        val token = authManager.refreshToken
            ?: throw MultandoError.AuthError("No refresh token available")
        val response = httpClient.request<TokenResponse>(
            method = "POST",
            path = "/api/v1/auth/refresh",
            body = RefreshRequest(token),
            authenticated = false
        )
        authManager.store(response)
        return response
    }

    /** Fetch the currently authenticated user's profile. */
    suspend fun me(): UserProfile =
        httpClient.request(method = "GET", path = "/api/v1/auth/me")

    /** Link a blockchain wallet to the authenticated account. */
    suspend fun linkWallet(request: WalletLinkRequest) {
        httpClient.requestVoid(
            method = "POST",
            path = "/api/v1/auth/link-wallet",
            body = request
        )
    }

    /** Log out by clearing stored tokens. */
    fun logout() {
        authManager.clearTokens()
    }
}

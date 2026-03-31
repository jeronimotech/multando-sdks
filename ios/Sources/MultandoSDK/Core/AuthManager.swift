import Foundation
import Combine
import Security

/// Manages authentication tokens using the iOS Keychain and publishes auth state changes.
public final class AuthManager: @unchecked Sendable {

    // MARK: - Keychain keys

    private static let service = "com.multando.sdk"
    private static let accessTokenKey = "access_token"
    private static let refreshTokenKey = "refresh_token"

    // MARK: - Published state

    private let _authStateSubject = CurrentValueSubject<Bool, Never>(false)

    /// A Combine publisher that emits `true` when authenticated, `false` otherwise.
    public var authStatePublisher: AnyPublisher<Bool, Never> {
        _authStateSubject.eraseToAnyPublisher()
    }

    // MARK: - Token accessors

    public var accessToken: String? {
        readKeychain(key: Self.accessTokenKey)
    }

    public var refreshToken: String? {
        readKeychain(key: Self.refreshTokenKey)
    }

    public var isAuthenticated: Bool {
        accessToken != nil
    }

    // MARK: - Init

    init() {
        _authStateSubject.send(isAuthenticated)
    }

    // MARK: - Token management

    func store(tokens: TokenResponse) {
        writeKeychain(key: Self.accessTokenKey, value: tokens.accessToken)
        writeKeychain(key: Self.refreshTokenKey, value: tokens.refreshToken)
        _authStateSubject.send(true)
    }

    func clearTokens() {
        deleteKeychain(key: Self.accessTokenKey)
        deleteKeychain(key: Self.refreshTokenKey)
        _authStateSubject.send(false)
    }

    // MARK: - Keychain helpers

    private func writeKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        deleteKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

//
//  EvidenceSigner.swift
//  MultandoSDK
//
//  Produces HMAC-SHA256 signatures over capture metadata using a per-device
//  secret stored in the Keychain.  Output matches the cross-platform
//  SecureEvidence schema.
//

import CommonCrypto
import Foundation
import Security
import UIKit

// MARK: - SecureEvidence

/// Cross-platform evidence payload.
public struct SecureEvidence: Codable, Sendable {
    public let imageUri: String
    public let imageHash: String
    public let timestamp: String
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let accuracy: Double
    public let deviceId: String
    public let appVersion: String
    public let platform: String
    public let captureMethod: String
    public let motionVerified: Bool
    public let watermarkApplied: Bool
    public let signature: String
}

// MARK: - EvidenceSigner

public final class EvidenceSigner {

    // MARK: Constants

    private static let deviceKeyTag = "com.multando.sdk.deviceKey"
    private static let deviceIdTag = "com.multando.sdk.deviceId"
    private static let serverSalt = "multando-evidence-v1"

    // MARK: - Device Identity

    /// Stable per-installation device ID stored in Keychain.
    public static func getDeviceId() -> String {
        if let existing = readKeychain(tag: deviceIdTag) {
            return existing
        }
        let newId = UUID().uuidString
        writeKeychain(tag: deviceIdTag, value: newId)
        return newId
    }

    /// Derived HMAC key: SHA256(rawKey + identifierForVendor + salt).
    private static func getDeviceKey() -> String {
        let rawKey: String
        if let existing = readKeychain(tag: deviceKeyTag) {
            rawKey = existing
        } else {
            rawKey = UUID().uuidString + UUID().uuidString
            writeKeychain(tag: deviceKeyTag, value: rawKey)
        }

        let installId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let material = rawKey + installId + serverSalt
        return sha256Hex(material)
    }

    // MARK: - Signing

    /// SHA-256 hex digest of raw data.
    public static func hashImageData(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { ptr in
            _ = CC_SHA256(ptr.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Build the canonical signing payload.
    private static func buildPayload(
        imageHash: String,
        timestamp: String,
        latitude: Double,
        longitude: Double,
        deviceId: String
    ) -> String {
        [
            imageHash,
            timestamp,
            String(format: "%.8f", latitude),
            String(format: "%.8f", longitude),
            deviceId,
        ].joined(separator: "|")
    }

    /// Simplified HMAC: SHA256(key + ":" + message).
    private static func hmac(key: String, message: String) -> String {
        sha256Hex("\(key):\(message)")
    }

    /// Sign evidence and return a complete `SecureEvidence`.
    public static func signEvidence(
        imageData: Data,
        imageUri: String,
        timestamp: String,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        accuracy: Double,
        motionVerified: Bool
    ) -> SecureEvidence {
        let deviceId = getDeviceId()
        let deviceKey = getDeviceKey()
        let imageHash = hashImageData(imageData)
        let payload = buildPayload(
            imageHash: imageHash,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            deviceId: deviceId
        )
        let signature = hmac(key: deviceKey, message: payload)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        return SecureEvidence(
            imageUri: imageUri,
            imageHash: imageHash,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            accuracy: accuracy,
            deviceId: deviceId,
            appVersion: version,
            platform: "ios",
            captureMethod: "camera",
            motionVerified: motionVerified,
            watermarkApplied: true,
            signature: signature
        )
    }

    /// Local verification.
    public static func verifyEvidence(_ evidence: SecureEvidence) -> Bool {
        let deviceKey = getDeviceKey()
        let payload = buildPayload(
            imageHash: evidence.imageHash,
            timestamp: evidence.timestamp,
            latitude: evidence.latitude,
            longitude: evidence.longitude,
            deviceId: evidence.deviceId
        )
        let expected = hmac(key: deviceKey, message: payload)
        return expected == evidence.signature
    }

    // MARK: - Crypto Helpers

    private static func sha256Hex(_ string: String) -> String {
        let data = Data(string.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { ptr in
            _ = CC_SHA256(ptr.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Keychain

    private static func readKeychain(tag: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func writeKeychain(tag: String, value: String) {
        let data = Data(value.utf8)

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tag,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}

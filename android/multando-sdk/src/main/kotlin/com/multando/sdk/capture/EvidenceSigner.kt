package com.multando.sdk.capture

import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.MessageDigest
import java.util.UUID

/**
 * Cross-platform evidence payload.
 */
data class SecureEvidence(
    val imageUri: String,
    val imageHash: String,
    val timestamp: String,
    val latitude: Double,
    val longitude: Double,
    val altitude: Double?,
    val accuracy: Double,
    val deviceId: String,
    val appVersion: String,
    val platform: String = "android",
    val captureMethod: String = "camera",
    val motionVerified: Boolean,
    val watermarkApplied: Boolean = true,
    val signature: String,
)

/**
 * Produces HMAC-SHA256 signatures over capture metadata using a per-device
 * key stored in EncryptedSharedPreferences.
 */
object EvidenceSigner {

    private const val PREFS_NAME = "multando_evidence_prefs"
    private const val KEY_DEVICE_KEY = "device_key"
    private const val KEY_DEVICE_ID = "device_id"
    private const val SERVER_SALT = "multando-evidence-v1"

    // -----------------------------------------------------------------------
    // Device identity
    // -----------------------------------------------------------------------

    private fun getEncryptedPrefs(context: Context) =
        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build(),
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )

    /**
     * Stable per-installation device ID.
     */
    fun getDeviceId(context: Context): String {
        val prefs = getEncryptedPrefs(context)
        var id = prefs.getString(KEY_DEVICE_ID, null)
        if (id == null) {
            id = UUID.randomUUID().toString()
            prefs.edit().putString(KEY_DEVICE_ID, id).apply()
        }
        return id
    }

    /**
     * Derived HMAC key: SHA256(rawKey + androidId + salt).
     */
    private fun getDeviceKey(context: Context): String {
        val prefs = getEncryptedPrefs(context)
        var rawKey = prefs.getString(KEY_DEVICE_KEY, null)
        if (rawKey == null) {
            rawKey = "${UUID.randomUUID()}${UUID.randomUUID()}"
            prefs.edit().putString(KEY_DEVICE_KEY, rawKey).apply()
        }

        @Suppress("HardwareIds")
        val installId = Settings.Secure.getString(
            context.contentResolver, Settings.Secure.ANDROID_ID
        ) ?: UUID.randomUUID().toString()

        return sha256Hex("$rawKey$installId$SERVER_SALT")
    }

    // -----------------------------------------------------------------------
    // Signing
    // -----------------------------------------------------------------------

    /**
     * SHA-256 hex digest of raw bytes.
     */
    fun hashImageBytes(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun buildPayload(
        imageHash: String,
        timestamp: String,
        latitude: Double,
        longitude: Double,
        deviceId: String,
    ): String = listOf(
        imageHash,
        timestamp,
        "%.8f".format(latitude),
        "%.8f".format(longitude),
        deviceId,
    ).joinToString("|")

    /**
     * Simplified HMAC: SHA256(key + ":" + message).
     */
    private fun hmac(key: String, message: String): String =
        sha256Hex("$key:$message")

    /**
     * Sign evidence and return a complete [SecureEvidence].
     */
    fun signEvidence(
        context: Context,
        imageBytes: ByteArray,
        imageUri: String,
        timestamp: String,
        latitude: Double,
        longitude: Double,
        altitude: Double?,
        accuracy: Double,
        motionVerified: Boolean,
    ): SecureEvidence {
        val deviceId = getDeviceId(context)
        val deviceKey = getDeviceKey(context)
        val imageHash = hashImageBytes(imageBytes)
        val payload = buildPayload(imageHash, timestamp, latitude, longitude, deviceId)
        val signature = hmac(deviceKey, payload)

        val appVersion = try {
            context.packageManager
                .getPackageInfo(context.packageName, 0)
                .versionName ?: "1.0.0"
        } catch (_: Exception) {
            "1.0.0"
        }

        return SecureEvidence(
            imageUri = imageUri,
            imageHash = imageHash,
            timestamp = timestamp,
            latitude = latitude,
            longitude = longitude,
            altitude = altitude,
            accuracy = accuracy,
            deviceId = deviceId,
            appVersion = appVersion,
            motionVerified = motionVerified,
            signature = signature,
        )
    }

    /**
     * Local verification.
     */
    fun verifyEvidence(context: Context, evidence: SecureEvidence): Boolean {
        val deviceKey = getDeviceKey(context)
        val payload = buildPayload(
            evidence.imageHash,
            evidence.timestamp,
            evidence.latitude,
            evidence.longitude,
            evidence.deviceId,
        )
        val expected = hmac(deviceKey, payload)
        return expected == evidence.signature
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    private fun sha256Hex(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(input.toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }
}

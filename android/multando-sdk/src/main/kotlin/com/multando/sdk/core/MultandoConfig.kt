package com.multando.sdk.core

/**
 * Configuration for the Multando SDK.
 *
 * @property baseUrl Base URL of the Multando API (no trailing slash).
 * @property apiKey API key issued to this application.
 * @property locale Locale sent in the Accept-Language header.
 * @property timeoutSeconds Request timeout in seconds.
 * @property enableOfflineQueue When true, mutating requests made offline are queued and replayed.
 * @property logLevel Logging verbosity.
 */
data class MultandoConfig(
    val baseUrl: String,
    val apiKey: String,
    val locale: String = "en",
    val timeoutSeconds: Long = 30,
    val enableOfflineQueue: Boolean = false,
    val logLevel: LogLevel = LogLevel.NONE
)

enum class LogLevel {
    NONE,
    ERROR,
    WARNING,
    INFO,
    DEBUG
}

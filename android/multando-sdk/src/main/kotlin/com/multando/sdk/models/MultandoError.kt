package com.multando.sdk.models

/** Scope of a rate-limit window returned by the backend. */
enum class RateLimitScope { HOUR, DAY }

/**
 * Errors thrown by the Multando SDK.
 */
sealed class MultandoError(override val message: String, override val cause: Throwable? = null) : Exception(message, cause) {

    /** The API returned a non-2xx status code. */
    open class ApiError(val statusCode: Int, message: String) :
        MultandoError("API error $statusCode: $message")

    /** A network-level failure occurred. */
    class NetworkError(cause: Throwable) :
        MultandoError("Network error: ${cause.message}", cause)

    /** A request was rejected due to invalid input. */
    class ValidationError(message: String) :
        MultandoError("Validation error: $message")

    /** An authentication operation failed. */
    class AuthError(message: String) :
        MultandoError("Auth error: $message")

    /** Response data could not be decoded into the expected type. */
    class DecodingError(cause: Throwable) :
        MultandoError("Decoding error: ${cause.message}", cause)

    /**
     * The user exceeded an hourly or daily report rate limit.
     *
     * Emitted when the backend returns HTTP 429 with
     * ``error: "rate_limit_exceeded"`` and a ``limit`` of either
     * ``reports_per_hour`` or ``reports_per_day``.
     */
    class RateLimitException(
        message: String,
        val retryAfterSeconds: Long,
        val scope: RateLimitScope,
    ) : ApiError(statusCode = 429, message = message)

    /**
     * The user (or all users) attempted to report a plate within its
     * cooldown window.
     *
     * Emitted when the backend returns HTTP 429 with a plate cooldown
     * ``limit`` (``same_plate_per_user_24h`` / ``plate_reports_24h``).
     */
    class PlateCooldownException(
        message: String,
        val plate: String,
        val retryAfterHours: Int,
    ) : ApiError(statusCode = 429, message = message)
}

/** Convenience aliases mirroring the public task spec naming. */
typealias RateLimitException = MultandoError.RateLimitException
typealias PlateCooldownException = MultandoError.PlateCooldownException

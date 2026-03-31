package com.multando.sdk.models

/**
 * Errors thrown by the Multando SDK.
 */
sealed class MultandoError(override val message: String, override val cause: Throwable? = null) : Exception(message, cause) {

    /** The API returned a non-2xx status code. */
    class ApiError(val statusCode: Int, message: String) :
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
}

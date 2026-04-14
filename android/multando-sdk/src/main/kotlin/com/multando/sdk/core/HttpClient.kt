package com.multando.sdk.core

import com.multando.sdk.models.MultandoError
import com.multando.sdk.models.RateLimitScope
import com.multando.sdk.models.RefreshRequest
import com.multando.sdk.models.TokenResponse
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.KSerializer
import kotlinx.serialization.serializer
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit

/**
 * HTTP client built on OkHttp with automatic auth header injection,
 * 401 token refresh via an Authenticator, and snake_case JSON conversion.
 */
class HttpClient internal constructor(
    private val config: MultandoConfig,
    private val authManager: AuthManager
) {
    internal val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        isLenient = true
        coerceInputValues = true
    }

    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    private val authInterceptor = Interceptor { chain ->
        val original = chain.request()
        val builder = original.newBuilder()
            .header("Accept", "application/json")
            .header("Content-Type", "application/json")
            .header("Accept-Language", config.locale)
            .header("X-API-Key", config.apiKey)

        if (original.header("No-Auth") == null) {
            authManager.accessToken?.let {
                builder.header("Authorization", "Bearer $it")
            }
        } else {
            builder.removeHeader("No-Auth")
        }

        chain.proceed(builder.build())
    }

    private val tokenAuthenticator = object : Authenticator {
        override fun authenticate(route: Route?, response: Response): Request? {
            // Only retry once
            if (response.request.header("X-Retry-Auth") != null) return null

            val refreshToken = authManager.refreshToken ?: return null
            val tokenResponse = try {
                runBlocking {
                    refreshTokens(refreshToken)
                }
            } catch (e: Exception) {
                authManager.clearTokens()
                return null
            }

            authManager.store(tokenResponse)

            return response.request.newBuilder()
                .header("Authorization", "Bearer ${tokenResponse.accessToken}")
                .header("X-Retry-Auth", "true")
                .build()
        }
    }

    internal val okHttpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
        .readTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
        .writeTimeout(config.timeoutSeconds, TimeUnit.SECONDS)
        .addInterceptor(authInterceptor)
        .authenticator(tokenAuthenticator)
        .build()

    // MARK: - Public request methods

    suspend inline fun <reified T> request(
        method: String,
        path: String,
        body: Any? = null,
        queryParams: Map<String, String>? = null,
        authenticated: Boolean = true
    ): T = withContext(Dispatchers.IO) {
        val responseBody = rawRequest(method, path, body, queryParams, authenticated)
        try {
            json.decodeFromString<T>(responseBody)
        } catch (e: Exception) {
            throw MultandoError.DecodingError(e)
        }
    }

    suspend fun requestVoid(
        method: String,
        path: String,
        body: Any? = null,
        queryParams: Map<String, String>? = null,
        authenticated: Boolean = true
    ) = withContext(Dispatchers.IO) {
        rawRequest(method, path, body, queryParams, authenticated)
    }

    // MARK: - Internal

    @PublishedApi
    internal suspend fun rawRequest(
        method: String,
        path: String,
        body: Any? = null,
        queryParams: Map<String, String>? = null,
        authenticated: Boolean = true
    ): String = withContext(Dispatchers.IO) {
        val urlBuilder = okhttp3.HttpUrl.Builder()
            .scheme(if (config.baseUrl.startsWith("https")) "https" else "http")

        val baseWithoutScheme = config.baseUrl
            .removePrefix("https://")
            .removePrefix("http://")

        val hostParts = baseWithoutScheme.split("/", limit = 2)
        val hostAndPort = hostParts[0]
        val basePath = if (hostParts.size > 1) "/" + hostParts[1] else ""

        if (hostAndPort.contains(":")) {
            val (host, port) = hostAndPort.split(":")
            urlBuilder.host(host).port(port.toInt())
        } else {
            urlBuilder.host(hostAndPort)
        }

        val fullPath = "$basePath$path".trimStart('/')
        fullPath.split("/").forEach { segment ->
            if (segment.isNotEmpty()) urlBuilder.addPathSegment(segment)
        }

        queryParams?.forEach { (key, value) ->
            urlBuilder.addQueryParameter(key, value)
        }

        val url = urlBuilder.build()

        val requestBody = when {
            body == null && method in listOf("POST", "PUT", "PATCH") ->
                "{}".toRequestBody(jsonMediaType)
            body is String ->
                body.toRequestBody(jsonMediaType)
            body != null ->
                json.encodeToString(serializer(body::class.java), body).toRequestBody(jsonMediaType)
            else -> null
        }

        val requestBuilder = Request.Builder()
            .url(url)
            .method(method, requestBody)

        if (!authenticated) {
            requestBuilder.header("No-Auth", "true")
        }

        val request = requestBuilder.build()
        val response = okHttpClient.newCall(request).execute()

        val responseBodyString = response.body?.string() ?: ""

        if (!response.isSuccessful) {
            if (response.code == 429) {
                mapRateLimitError(responseBodyString, response.header("Retry-After"))?.let { throw it }
            }
            throw MultandoError.ApiError(
                statusCode = response.code,
                message = responseBodyString.ifEmpty { response.message }
            )
        }

        responseBodyString
    }

    /**
     * Parse a structured 429 body into a typed [MultandoError.RateLimitException] or
     * [MultandoError.PlateCooldownException]. Returns null if the body isn't
     * recognized — the caller will fall back to a generic [MultandoError.ApiError].
     *
     * Expected body shape:
     * ```
     * { "detail": {
     *     "error": "rate_limit_exceeded",
     *     "limit": "reports_per_hour" | "reports_per_day" | "same_plate_per_user_24h" | "plate_reports_24h",
     *     "retry_after_seconds": 3600,
     *     "message": "..."
     *   }
     * }
     * ```
     * The SDK also accepts legacy bodies where the payload is flat (no
     * ``detail`` wrapper) or uses ``error_code`` instead of ``error``.
     */
    private fun mapRateLimitError(body: String, retryAfterHeader: String?): MultandoError? {
        if (body.isBlank()) return null
        val root = try {
            json.parseToJsonElement(body).jsonObject
        } catch (_: Exception) {
            return null
        }

        // FastAPI wraps HTTPException payloads under "detail".
        val payload: JsonObject = (root["detail"] as? JsonObject) ?: root

        val code = payload["error"]?.jsonPrimitive?.contentOrNull
            ?: payload["error_code"]?.jsonPrimitive?.contentOrNull
        val limit = payload["limit"]?.jsonPrimitive?.contentOrNull
        val message = payload["message"]?.jsonPrimitive?.contentOrNull
            ?: body

        val retryAfterSeconds: Long = payload["retry_after_seconds"]?.jsonPrimitive?.longOrNull
            ?: retryAfterHeader?.toLongOrNull()
            ?: 0L

        val isPlateCooldown = code == "plate_cooldown" ||
            limit == "same_plate_per_user_24h" ||
            limit == "plate_reports_24h"

        if (isPlateCooldown) {
            val plate = payload["plate"]?.jsonPrimitive?.contentOrNull ?: ""
            val retryAfterHours = ((retryAfterSeconds + 3599) / 3600).toInt().coerceAtLeast(1)
            return MultandoError.PlateCooldownException(
                message = message,
                plate = plate,
                retryAfterHours = retryAfterHours,
            )
        }

        if (code == "rate_limit_exceeded") {
            val scope = when (limit) {
                "reports_per_day" -> RateLimitScope.DAY
                else -> RateLimitScope.HOUR
            }
            return MultandoError.RateLimitException(
                message = message,
                retryAfterSeconds = retryAfterSeconds,
                scope = scope,
            )
        }

        return null
    }

    private suspend fun refreshTokens(refreshToken: String): TokenResponse {
        val body = json.encodeToString(RefreshRequest.serializer(), RefreshRequest(refreshToken))
        val requestBody = body.toRequestBody(jsonMediaType)

        val url = "${config.baseUrl}/api/v1/auth/refresh"
        val request = Request.Builder()
            .url(url)
            .post(requestBody)
            .header("Content-Type", "application/json")
            .header("X-API-Key", config.apiKey)
            .build()

        return withContext(Dispatchers.IO) {
            val response = okHttpClient.newCall(request).execute()
            val responseBody = response.body?.string() ?: ""
            if (!response.isSuccessful) {
                throw MultandoError.ApiError(response.code, responseBody)
            }
            json.decodeFromString(TokenResponse.serializer(), responseBody)
        }
    }
}

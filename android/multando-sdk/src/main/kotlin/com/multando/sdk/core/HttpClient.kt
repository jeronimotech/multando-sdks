package com.multando.sdk.core

import com.multando.sdk.models.MultandoError
import com.multando.sdk.models.RefreshRequest
import com.multando.sdk.models.TokenResponse
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
            throw MultandoError.ApiError(
                statusCode = response.code,
                message = responseBodyString.ifEmpty { response.message }
            )
        }

        responseBodyString
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

package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.InfractionResponse

/**
 * Fetches and caches infraction types.
 */
class InfractionService internal constructor(
    private val httpClient: HttpClient
) {
    private var cache: List<InfractionResponse>? = null
    private var cacheTimestamp: Long = 0
    private val cacheTtlMs: Long = 300_000 // 5 minutes

    /** List all available infraction types. Results are cached for 5 minutes. */
    suspend fun list(forceRefresh: Boolean = false): List<InfractionResponse> {
        if (!forceRefresh) {
            cache?.let {
                if (System.currentTimeMillis() - cacheTimestamp < cacheTtlMs) return it
            }
        }

        val infractions = httpClient.request<List<InfractionResponse>>(
            method = "GET",
            path = "/api/v1/infractions"
        )

        synchronized(this) {
            cache = infractions
            cacheTimestamp = System.currentTimeMillis()
        }

        return infractions
    }

    /** Fetch a single infraction by ID. */
    suspend fun get(id: String): InfractionResponse =
        httpClient.request(method = "GET", path = "/api/v1/infractions/$id")

    /** Clear the in-memory cache. */
    fun clearCache() {
        synchronized(this) {
            cache = null
            cacheTimestamp = 0
        }
    }
}

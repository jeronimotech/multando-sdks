package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.VehicleTypeResponse

/**
 * Fetches and caches vehicle types.
 */
class VehicleTypeService internal constructor(
    private val httpClient: HttpClient
) {
    private var cache: List<VehicleTypeResponse>? = null
    private var cacheTimestamp: Long = 0
    private val cacheTtlMs: Long = 300_000 // 5 minutes

    /** List all vehicle types. Results are cached for 5 minutes. */
    suspend fun list(forceRefresh: Boolean = false): List<VehicleTypeResponse> {
        if (!forceRefresh) {
            cache?.let {
                if (System.currentTimeMillis() - cacheTimestamp < cacheTtlMs) return it
            }
        }

        val types = httpClient.request<List<VehicleTypeResponse>>(
            method = "GET",
            path = "/api/v1/vehicle-types"
        )

        synchronized(this) {
            cache = types
            cacheTimestamp = System.currentTimeMillis()
        }

        return types
    }

    /** Fetch a single vehicle type by ID. */
    suspend fun get(id: String): VehicleTypeResponse =
        httpClient.request(method = "GET", path = "/api/v1/vehicle-types/$id")

    /** Clear the in-memory cache. */
    fun clearCache() {
        synchronized(this) {
            cache = null
            cacheTimestamp = 0
        }
    }
}

package com.multando.sdk.core

import android.content.Context
import com.multando.sdk.models.UserProfile
import com.multando.sdk.services.*

/**
 * Main Multando SDK client holding references to all sub-services.
 */
class MultandoClient internal constructor(
    context: Context,
    val config: MultandoConfig
) {
    internal val authManager = AuthManager(context)
    internal val httpClient = HttpClient(config, authManager)
    internal val offlineQueue: OfflineQueue? =
        if (config.enableOfflineQueue) OfflineQueue(context, httpClient) else null

    val auth = AuthService(httpClient, authManager)
    val reports = ReportService(httpClient)
    val evidence = EvidenceService(httpClient)
    val infractions = InfractionService(httpClient)
    val vehicleTypes = VehicleTypeService(httpClient)
    val verification = VerificationService(httpClient)
    val blockchain = BlockchainService(httpClient)

    /** Whether the user currently has valid auth tokens stored. */
    val isAuthenticated: Boolean get() = authManager.isAuthenticated

    /** Fetches the profile of the currently authenticated user. */
    suspend fun currentUser(): UserProfile = auth.me()

    /** Tears down network monitors and clears in-memory caches. */
    fun dispose() {
        offlineQueue?.stop()
        infractions.clearCache()
        vehicleTypes.clearCache()
    }
}

package com.multando.sdk

import android.content.Context
import com.multando.sdk.chat.ChatService
import com.multando.sdk.core.MultandoClient
import com.multando.sdk.core.MultandoConfig
import com.multando.sdk.services.*

/**
 * Entry point for the Multando SDK.
 *
 * Call [initialize] once with an application [Context] and [MultandoConfig], then access
 * sub-services through the returned [MultandoClient] or through the companion properties.
 */
object MultandoSDK {

    const val VERSION = "1.1.0"

    @Volatile
    private var _client: MultandoClient? = null

    /** The initialized client instance. Throws if [initialize] has not been called. */
    val client: MultandoClient
        get() = _client ?: throw IllegalStateException("MultandoSDK.initialize() must be called first")

    val auth: AuthService get() = client.auth
    val reports: ReportService get() = client.reports
    val evidence: EvidenceService get() = client.evidence
    val infractions: InfractionService get() = client.infractions
    val vehicleTypes: VehicleTypeService get() = client.vehicleTypes
    val verification: VerificationService get() = client.verification
    val blockchain: BlockchainService get() = client.blockchain
    val chat: ChatService get() = client.chat

    /**
     * Initialize the SDK. Must be called before accessing any service.
     *
     * @param context Application context (will be stored as application context).
     * @param config SDK configuration.
     * @return The initialized [MultandoClient].
     */
    fun initialize(context: Context, config: MultandoConfig): MultandoClient {
        val appContext = context.applicationContext
        val client = MultandoClient(appContext, config)
        _client = client
        return client
    }

    /** Whether the SDK has been initialized. */
    val isInitialized: Boolean get() = _client != null

    /** Tear down the SDK, releasing resources. */
    fun dispose() {
        _client?.dispose()
        _client = null
    }
}

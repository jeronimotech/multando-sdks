package com.multando.sdk.core

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import kotlinx.coroutines.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.util.UUID

/**
 * Persists mutating HTTP requests as JSON and replays them when connectivity returns.
 * Uses ConnectivityManager to listen for network changes.
 */
class OfflineQueue internal constructor(
    private val context: Context,
    private val httpClient: HttpClient
) {
    @Serializable
    data class QueuedRequest(
        val id: String,
        val method: String,
        val path: String,
        val body: String? = null,
        val timestamp: Long
    )

    private val json = Json { ignoreUnknownKeys = true }
    private val queueFile: File
        get() {
            val dir = File(context.filesDir, "multando_sdk")
            if (!dir.exists()) dir.mkdirs()
            return File(dir, "offline_queue.json")
        }

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var isProcessing = false

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            scope.launch { processQueue() }
        }
    }

    init {
        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
        connectivityManager.registerNetworkCallback(request, networkCallback)
    }

    /** Whether the device currently has internet connectivity. */
    val hasConnectivity: Boolean
        get() {
            val network = connectivityManager.activeNetwork ?: return false
            val caps = connectivityManager.getNetworkCapabilities(network) ?: return false
            return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        }

    /** Enqueue a request for later replay. */
    fun enqueue(method: String, path: String, body: String? = null) {
        synchronized(this) {
            val items = loadQueue().toMutableList()
            items.add(
                QueuedRequest(
                    id = UUID.randomUUID().toString(),
                    method = method,
                    path = path,
                    body = body,
                    timestamp = System.currentTimeMillis()
                )
            )
            saveQueue(items)
        }
    }

    /** Stop listening for connectivity changes. */
    fun stop() {
        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
        } catch (_: Exception) { }
        scope.cancel()
    }

    private suspend fun processQueue() {
        if (isProcessing) return
        isProcessing = true
        try {
            val items = synchronized(this) { loadQueue() }
            val failed = mutableListOf<QueuedRequest>()

            for (item in items) {
                try {
                    httpClient.requestVoid(
                        method = item.method,
                        path = item.path,
                        body = item.body,
                        authenticated = true
                    )
                } catch (_: Exception) {
                    failed.add(item)
                }
            }

            synchronized(this) { saveQueue(failed) }
        } finally {
            isProcessing = false
        }
    }

    private fun loadQueue(): List<QueuedRequest> {
        return try {
            val text = queueFile.readText()
            if (text.isBlank()) emptyList()
            else json.decodeFromString<List<QueuedRequest>>(text)
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun saveQueue(items: List<QueuedRequest>) {
        queueFile.writeText(json.encodeToString(items))
    }
}

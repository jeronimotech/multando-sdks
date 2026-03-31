package com.multando.sdk

import com.multando.sdk.core.MultandoConfig
import com.multando.sdk.core.LogLevel
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class MultandoClientTest {

    @Test
    fun `MultandoConfig preserves all values`() {
        val config = MultandoConfig(
            baseUrl = "https://api.test.multando.io",
            apiKey = "test-key-123",
            locale = "es",
            timeoutSeconds = 60,
            enableOfflineQueue = true,
            logLevel = LogLevel.DEBUG,
        )

        assertEquals("https://api.test.multando.io", config.baseUrl)
        assertEquals("test-key-123", config.apiKey)
        assertEquals("es", config.locale)
        assertEquals(60L, config.timeoutSeconds)
        assertTrue(config.enableOfflineQueue)
        assertEquals(LogLevel.DEBUG, config.logLevel)
    }

    @Test
    fun `MultandoConfig has sensible defaults`() {
        val config = MultandoConfig(
            baseUrl = "https://api.multando.io",
            apiKey = "key",
        )

        assertEquals("en", config.locale)
        assertEquals(30L, config.timeoutSeconds)
        assertFalse(config.enableOfflineQueue)
        assertEquals(LogLevel.NONE, config.logLevel)
    }

    @Test
    fun `MultandoSDK isInitialized is false before initialize`() {
        assertFalse(MultandoSDK.isInitialized)
    }

    @Test
    fun `MultandoSDK version is set`() {
        assertEquals("1.0.0", MultandoSDK.VERSION)
    }

    @Test
    fun `MultandoSDK client throws before initialize`() {
        // Reset state.
        MultandoSDK.dispose()

        try {
            MultandoSDK.client
            assertTrue("Should have thrown", false)
        } catch (e: IllegalStateException) {
            assertTrue(e.message?.contains("initialize") == true)
        }
    }

    @Test
    fun `MultandoSDK dispose is safe when not initialized`() {
        MultandoSDK.dispose()
        assertFalse(MultandoSDK.isInitialized)
    }

    @Test
    fun `MultandoConfig data class equality`() {
        val a = MultandoConfig(baseUrl = "https://api.io", apiKey = "k1")
        val b = MultandoConfig(baseUrl = "https://api.io", apiKey = "k1")
        val c = MultandoConfig(baseUrl = "https://api.io", apiKey = "k2")

        assertEquals(a, b)
        assertFalse(a == c)
    }

    @Test
    fun `MultandoConfig data class copy`() {
        val original = MultandoConfig(baseUrl = "https://api.io", apiKey = "key")
        val modified = original.copy(locale = "fr", logLevel = LogLevel.INFO)

        assertEquals("fr", modified.locale)
        assertEquals(LogLevel.INFO, modified.logLevel)
        assertEquals(original.baseUrl, modified.baseUrl)
        assertEquals(original.apiKey, modified.apiKey)
    }

    @Test
    fun `LogLevel enum has expected values`() {
        val levels = LogLevel.values()
        assertEquals(5, levels.size)
        assertNotNull(LogLevel.valueOf("NONE"))
        assertNotNull(LogLevel.valueOf("ERROR"))
        assertNotNull(LogLevel.valueOf("WARNING"))
        assertNotNull(LogLevel.valueOf("INFO"))
        assertNotNull(LogLevel.valueOf("DEBUG"))
    }
}

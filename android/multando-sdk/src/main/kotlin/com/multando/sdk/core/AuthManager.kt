package com.multando.sdk.core

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.multando.sdk.models.TokenResponse
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Securely stores authentication tokens using EncryptedSharedPreferences
 * and exposes auth state as a Kotlin Flow.
 */
class AuthManager internal constructor(context: Context) {

    private companion object {
        const val PREFS_NAME = "com.multando.sdk.auth"
        const val KEY_ACCESS_TOKEN = "access_token"
        const val KEY_REFRESH_TOKEN = "refresh_token"
    }

    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        PREFS_NAME,
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    private val _authState = MutableStateFlow(accessToken != null)

    /** Flow that emits `true` when authenticated, `false` otherwise. */
    val authState: StateFlow<Boolean> = _authState.asStateFlow()

    /** Current access token, or null. */
    val accessToken: String?
        get() = prefs.getString(KEY_ACCESS_TOKEN, null)

    /** Current refresh token, or null. */
    val refreshToken: String?
        get() = prefs.getString(KEY_REFRESH_TOKEN, null)

    /** Whether valid tokens are stored. */
    val isAuthenticated: Boolean
        get() = accessToken != null

    /** Persist a new token pair. */
    fun store(tokens: TokenResponse) {
        prefs.edit()
            .putString(KEY_ACCESS_TOKEN, tokens.accessToken)
            .putString(KEY_REFRESH_TOKEN, tokens.refreshToken)
            .apply()
        _authState.value = true
    }

    /** Remove all stored tokens. */
    fun clearTokens() {
        prefs.edit()
            .remove(KEY_ACCESS_TOKEN)
            .remove(KEY_REFRESH_TOKEN)
            .apply()
        _authState.value = false
    }
}

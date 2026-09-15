package com.orko_hubco.mobile.orko_hubco.auto

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.util.Log
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.screens.NearbyStationsScreen
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * A single Android Auto session. The host creates one [OrkoSession] per car
 * connection and asks it for the root [Screen].
 *
 * Owns the [FlutterAutoBridge] (cached FlutterEngine + data channel) and tears
 * it down with the session.
 *
 * AUTH GATE: the root is [NearbyStationsScreen], which self-gates. The session
 * token lives only in Dart/SecureStore and — by design — is never read
 * synchronously from native, so [onCreateScreen] cannot branch on it up front.
 * Instead the root's first bridge call returns the "auth" code when there is no
 * session, and the screen routes to SignInRequiredScreen. Any later "auth" (a
 * session expiring mid-use) routes there the same way.
 */
class OrkoSession : Session(), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val bridge: FlutterAutoBridge by lazy { FlutterAutoBridge(carContext) }

    init {
        lifecycle.addObserver(this)
    }

    override fun onCreateScreen(intent: Intent): Screen {
        // Debug-only sanity check: confirms the cached FlutterEngine boots the
        // Dart entrypoint and the channel round-trips. Never logs the token.
        if (isDebuggable()) {
            scope.launch {
                try {
                    val authed = bridge.isAuthenticated()
                    Log.d(TAG, "bridge isAuthenticated -> $authed")
                } catch (e: Exception) {
                    Log.d(TAG, "bridge round-trip failed: ${e.message}")
                }
            }
        }
        // Root authenticated flow. If there is no session, NearbyStationsScreen
        // receives an "auth" result from the bridge and routes to sign-in.
        return NearbyStationsScreen(carContext, bridge)
    }

    override fun onDestroy(owner: LifecycleOwner) {
        // Cancel our own coroutines first so nothing calls the bridge during or
        // after teardown, then destroy the engine (screens cancel their own
        // scopes via their DefaultLifecycleObserver before this runs).
        scope.cancel()
        bridge.destroy()
    }

    private fun isDebuggable(): Boolean =
        (carContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    companion object {
        private const val TAG = "OrkoAuto"
    }
}

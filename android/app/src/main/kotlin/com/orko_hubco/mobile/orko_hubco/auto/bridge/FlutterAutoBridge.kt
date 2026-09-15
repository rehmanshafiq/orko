package com.orko_hubco.mobile.orko_hubco.auto.bridge

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume

/**
 * Bridges the Android Auto car app (Kotlin) to the app's real Dart data layer.
 *
 * Owns a cached [FlutterEngine] that runs the dedicated `androidAutoMain`
 * entrypoint, which reuses the app's network/auth/config stack and exposes
 * read-only data over the `orko/android_auto` [MethodChannel]. All calls return
 * the decoded result map from Dart; the access token never crosses the channel.
 *
 * Created lazily on first use; [destroy] tears the engine down (called from the
 * Session lifecycle — see Phase 9).
 */
class FlutterAutoBridge(context: Context) {

    private val appContext = context.applicationContext
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null

    /**
     * Once torn down, the bridge stays down. Prevents a late coroutine (a call
     * racing with Session teardown) from resurrecting the engine after
     * [destroy], which would leak an engine with no owning session.
     */
    private var destroyed = false

    companion object {
        private const val CHANNEL = "orko/android_auto"
        private const val ENTRYPOINT = "androidAutoMain"
        private val ERROR_SERVER: Map<String, Any?> =
            mapOf("ok" to false, "error" to "server")
    }

    /**
     * Boots the cached engine + channel exactly once. Must run on the main
     * thread. No-op once [destroy] has been called, so a late call cannot
     * resurrect the engine.
     */
    @Synchronized
    private fun ensureStarted() {
        if (destroyed || engine != null) return
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)

        val e = FlutterEngine(appContext)
        val entrypoint = DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT)
        e.dartExecutor.executeDartEntrypoint(entrypoint)
        engine = e
        channel = MethodChannel(e.dartExecutor.binaryMessenger, CHANNEL)
    }

    /**
     * Invokes a Dart method and returns its decoded result map. Never throws —
     * channel errors/absence map to a `{ok:false, error:"server"}` result.
     */
    @Suppress("UNCHECKED_CAST")
    suspend fun call(method: String, args: Map<String, Any?>? = null): Map<String, Any?> =
        withContext(Dispatchers.Main) {
            ensureStarted()
            val ch = channel ?: return@withContext ERROR_SERVER
            suspendCancellableCoroutine { cont ->
                ch.invokeMethod(method, args, object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        cont.resume((result as? Map<String, Any?>) ?: emptyMap())
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        cont.resume(ERROR_SERVER)
                    }

                    override fun notImplemented() {
                        cont.resume(ERROR_SERVER)
                    }
                })
            }
        }

    suspend fun isAuthenticated(): Boolean =
        call("isAuthenticated")["authenticated"] == true

    suspend fun getNearbyStations(lat: Double? = null, lng: Double? = null): Map<String, Any?> {
        val args = HashMap<String, Any?>()
        if (lat != null) args["lat"] = lat
        if (lng != null) args["lng"] = lng
        return call("getNearbyStations", args)
    }

    suspend fun getStationDetail(id: String, lat: Double, lng: Double): Map<String, Any?> =
        call("getStationDetail", mapOf("id" to id, "lat" to lat, "lng" to lng))

    suspend fun getLiveSession(): Map<String, Any?> = call("getLiveSession")

    suspend fun getSavedTrips(): Map<String, Any?> = call("getSavedTrips")

    suspend fun getSavedTripDetail(id: Int): Map<String, Any?> =
        call("getSavedTripDetail", mapOf("id" to id))

    /**
     * Tears down the channel + engine and marks the bridge permanently
     * destroyed. Idempotent; call on Session destroy (main thread). Destroying
     * the engine ends its Dart isolate, which clears the in-memory decrypted
     * token mirror (SecureStore) held there — no token state lingers.
     */
    @Synchronized
    fun destroy() {
        destroyed = true
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
    }
}

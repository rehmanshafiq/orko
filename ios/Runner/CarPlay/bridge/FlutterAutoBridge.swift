import Flutter
import Foundation
import firebase_core
import firebase_remote_config
import flutter_secure_storage
import geolocator_apple
import package_info_plus
import path_provider_foundation

/// Bridges the CarPlay car app (Swift) to the app's real Dart data layer.
/// iOS counterpart of FlutterAutoBridge.kt — same channel, same methods, same
/// result maps, so the Dart side (`android_auto_bridge.dart`) is shared as-is.
///
/// Owns a dedicated [FlutterEngine] that runs the `carPlayMain` entrypoint
/// (same body as Android's `androidAutoMain`), which reuses the app's
/// network/auth/config stack and exposes read-only data over the
/// `orko/android_auto` [FlutterMethodChannel]. The access token never crosses
/// the channel.
///
/// TWO ENGINES: this engine runs alongside the phone app's engine with its own
/// isolate and no shared Dart state. Both read the token from SecureStore
/// (Keychain, `first_unlock_this_device`) and fetch everything else from the
/// backend per call — the same model as Android.
///
/// Created lazily on first use; [destroy] tears the engine down (called by
/// OrkoSession when the car disconnects — never by phone-app lifecycle).
@MainActor
final class FlutterAutoBridge {

    typealias Result = [String: Any]

    private static let channelName = "orko/android_auto"
    private static let entrypoint = "carPlayMain"
    private static let errorServer: Result = ["ok": false, "error": "server"]

    private var engine: FlutterEngine?
    private var channel: FlutterMethodChannel?

    /// Once torn down, the bridge stays down, so a late call racing with
    /// disconnect cannot resurrect an engine with no owning session.
    private var destroyed = false

    /// In-flight calls, resumed with a server error on [destroy] so no caller
    /// is left suspended forever when the engine goes away mid-call.
    private var pending: [UUID: CheckedContinuation<Result, Never>] = [:]

    /// Boots the engine + channel exactly once. No-op after [destroy].
    private func ensureStarted() {
        guard !destroyed, engine == nil else { return }
        let e = FlutterEngine(name: "orko_carplay", project: nil, allowHeadlessExecution: true)
        guard e.run(withEntrypoint: Self.entrypoint) else { return }
        registerCarPlugins(on: e)
        engine = e
        channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: e.binaryMessenger)
        FlutterEngineHolder.shared.registerCarPlay(messenger: e.binaryMessenger)
    }

    /// Registers ONLY the native plugins the car bridge's Dart code uses
    /// (computed from its transitive imports). Deliberately not
    /// GeneratedPluginRegistrant: plugins such as firebase_messaging and
    /// flutter_local_notifications take over the process-wide
    /// UNUserNotificationCenter delegate when registered, which would steal
    /// notification delivery from the phone engine.
    private func registerCarPlugins(on e: FlutterEngine) {
        func add(_ key: String, _ register: (FlutterPluginRegistrar) -> Void) {
            if let registrar = e.registrar(forPlugin: key) { register(registrar) }
        }
        add("FLTFirebaseCorePlugin") { FLTFirebaseCorePlugin.register(with: $0) }
        add("FirebaseRemoteConfigPlugin") { FirebaseRemoteConfigPlugin.register(with: $0) }
        add("FlutterSecureStoragePlugin") { FlutterSecureStoragePlugin.register(with: $0) }
        add("GeolocatorPlugin") { GeolocatorPlugin.register(with: $0) }
        add("FPPPackageInfoPlusPlugin") { FPPPackageInfoPlusPlugin.register(with: $0) }
        add("PathProviderPlugin") { PathProviderPlugin.register(with: $0) }
    }

    /// Invokes a Dart method and returns its decoded result map. Never throws —
    /// channel errors/absence map to a `{ok:false, error:"server"}` result.
    func call(_ method: String, _ args: [String: Any]? = nil) async -> Result {
        ensureStarted()
        guard let ch = channel else { return Self.errorServer }
        let id = UUID()
        return await withCheckedContinuation { cont in
            pending[id] = cont
            ch.invokeMethod(method, arguments: args) { [weak self] reply in
                MainActor.assumeIsolatedCompat { self?.complete(id, reply) }
            }
        }
    }

    private func complete(_ id: UUID, _ reply: Any?) {
        guard let cont = pending.removeValue(forKey: id) else { return }
        if reply is FlutterError || (reply as AnyObject?) === FlutterMethodNotImplemented {
            cont.resume(returning: Self.errorServer)
        } else {
            cont.resume(returning: (reply as? Result) ?? [:])
        }
    }

    func isAuthenticated() async -> Bool {
        (await call("isAuthenticated"))["authenticated"] as? Bool == true
    }

    func getNearbyStations(lat: Double? = nil, lng: Double? = nil) async -> Result {
        var args: [String: Any] = [:]
        if let lat { args["lat"] = lat }
        if let lng { args["lng"] = lng }
        return await call("getNearbyStations", args)
    }

    func getStationDetail(id: String, lat: Double, lng: Double) async -> Result {
        await call("getStationDetail", ["id": id, "lat": lat, "lng": lng])
    }

    func getLiveSession() async -> Result { await call("getLiveSession") }

    func getSavedTrips() async -> Result { await call("getSavedTrips") }

    func getSavedTripDetail(id: Int) async -> Result {
        await call("getSavedTripDetail", ["id": id])
    }

    /// Tears down the channel + engine and marks the bridge permanently
    /// destroyed. Idempotent. Destroying the engine ends its Dart isolate, which
    /// clears the in-memory decrypted token mirror held there.
    func destroy() {
        destroyed = true
        let waiting = pending
        pending.removeAll()
        waiting.values.forEach { $0.resume(returning: Self.errorServer) }
        channel?.setMethodCallHandler(nil)
        channel = nil
        engine?.destroyContext()
        engine = nil
        FlutterEngineHolder.shared.clearCarPlay()
    }
}

import CarPlay

/// A single CarPlay session — one per car connection. Counterpart of
/// OrkoSession.kt: owns the [FlutterAutoBridge] (dedicated FlutterEngine + data
/// channel) and the screen stack, and tears both down with the connection.
///
/// AUTH GATE: the root is [NearbyStationsScreen], which self-gates. The session
/// token lives only in Dart/SecureStore and is never read synchronously from
/// native, so the root's first bridge call returns "auth" when there is no
/// session and the screen routes to SignInRequiredScreen.
@MainActor
final class OrkoSession {

    private let bridge = FlutterAutoBridge()
    private let screenManager: CarScreenManager

    init(scene: CPTemplateApplicationScene, interfaceController: CPInterfaceController) {
        screenManager = CarScreenManager(interfaceController: interfaceController, scene: scene)
    }

    func start() {
        screenManager.setRoot(NearbyStationsScreen(bridge: bridge))
    }

    func setSceneActive(_ active: Bool) {
        screenManager.setSceneActive(active)
    }

    func destroy() {
        // Screens cancel their own tasks first so nothing calls the bridge during
        // or after teardown, then the engine is destroyed.
        screenManager.destroyAll()
        bridge.destroy()
    }
}

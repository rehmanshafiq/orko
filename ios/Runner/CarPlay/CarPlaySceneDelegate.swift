import CarPlay
import UIKit

/// CarPlay entry point for HUBCO Green (CPTemplateApplicationSceneSessionRoleApplication,
/// declared in Info.plist). Counterpart of OrkoCarAppService.kt.
///
/// Requires the `com.apple.developer.carplay-charging` entitlement. It hosts
/// native CarPlay templates only — no Flutter UI is rendered in the car.
///
/// LIFECYCLE / ENGINE OWNERSHIP: one [OrkoSession] per car connection. The
/// CarPlay FlutterEngine is created on connect (lazily, on first bridge call)
/// and destroyed on disconnect, here and only here. Phone-app scene events
/// never reach this delegate, so the phone can't tear the car engine down, and
/// this delegate never touches the phone engine.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    private var session: OrkoSession?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        session?.destroy()
        let s = OrkoSession(scene: templateApplicationScene, interfaceController: interfaceController)
        session = s
        s.start()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        session?.destroy()
        session = nil
    }

    // The driver switched to another CarPlay app and back (Android: the host
    // stopping / restarting the visible screen).
    func sceneDidEnterBackground(_ scene: UIScene) {
        session?.setSceneActive(false)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        session?.setSceneActive(true)
    }
}

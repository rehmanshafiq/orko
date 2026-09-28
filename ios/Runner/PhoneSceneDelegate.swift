import Flutter
import GoogleSignIn
import UIKit

/// Scene delegate for the phone UI (UIWindowSceneSessionRoleApplication).
///
/// Subclasses Flutter's own [FlutterSceneDelegate], which creates the window
/// from the Main storyboard and forwards every scene event to plugins that
/// registered for scene lifecycle callbacks (firebase_messaging,
/// flutter_local_notifications, flutter_foreground_task, …). Every override
/// here calls `super` so that forwarding is never lost.
///
/// Only fills the gaps left by plugins that still listen solely on the
/// UIApplicationDelegate path, which UIKit stops calling once the app adopts
/// scenes.
///
/// NOTIFICATIONS: cold launch from a notification tap arrives here as
/// `connectionOptions.notificationResponse`. firebase_messaging already reads it
/// itself through its scene-delegate registration, so it is deliberately NOT
/// forwarded again here — doing so would deliver the tap twice. Tap routing is
/// done in Dart (PushNotificationService), so no native router needs a
/// view-controller reference.
final class PhoneSceneDelegate: FlutterSceneDelegate {

    /// The Flutter view controller of this scene's own window (never
    /// `AppDelegate.window`, which is nil under scenes).
    var flutterViewController: FlutterViewController? {
        window?.rootViewController as? FlutterViewController
    }

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        // Cold launch via URL: delivered only here, never to
        // scene(_:openURLContexts:).
        handleGoogleSignIn(connectionOptions.urlContexts)
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Warm launch via URL. google_sign_in_ios (5.9.x) only implements
        // application(_:open:options:), which is not called under scenes; without
        // this the OAuth return is dropped and sign-in hangs after the browser.
        if handleGoogleSignIn(URLContexts) { return }
        super.scene(scene, openURLContexts: URLContexts)
    }

    /// Hands any Google Sign-In redirect to GIDSignIn. Returns true if one was
    /// consumed. The only CFBundleURLSchemes entry is the Google reversed
    /// client ID; there is no other custom scheme or universal link.
    @discardableResult
    private func handleGoogleSignIn(_ contexts: Set<UIOpenURLContext>) -> Bool {
        for context in contexts where GIDSignIn.sharedInstance.handle(context.url) {
            return true
        }
        return false
    }
}

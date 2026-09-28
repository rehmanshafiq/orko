import Flutter
import Foundation

/// Holds the binary messenger of each FlutterEngine the app runs, captured at
/// plugin-registration time.
///
/// Native channels must NOT look the messenger up lazily through
/// `window?.rootViewController`: under the UIScene lifecycle
/// `AppDelegate.window` is nil, and that lookup silently returns nil — the
/// channel is never registered, with no crash and no error. A messenger
/// captured in `register(with:)` is identical under scenes and legacy launch.
///
/// Two engines can be alive at once (mirrors Android Auto): the phone app's
/// engine and the CarPlay engine. They share no Dart state, so each messenger
/// is kept separately and every channel must say which engine it belongs to.
final class FlutterEngineHolder {
    static let shared = FlutterEngineHolder()

    /// Messenger of the phone app's engine (the one behind the phone UI).
    private(set) var phoneMessenger: FlutterBinaryMessenger?

    /// Messenger of the CarPlay engine. Set on CarPlay connect, cleared on
    /// disconnect by the CarPlay scene delegate that owns that engine.
    private(set) var carPlayMessenger: FlutterBinaryMessenger?

    private init() {}

    func registerPhone(messenger: FlutterBinaryMessenger) { phoneMessenger = messenger }

    func registerCarPlay(messenger: FlutterBinaryMessenger) { carPlayMessenger = messenger }

    func clearCarPlay() { carPlayMessenger = nil }
}

/// Captures the phone engine's messenger. Registered against the phone
/// engine's plugin registry only — never against the CarPlay engine — so
/// [FlutterEngineHolder.phoneMessenger] always belongs to the phone app.
final class PhoneEngineMessengerPlugin: NSObject, FlutterPlugin {
    static let key = "PhoneEngineMessengerPlugin"

    static func register(with registrar: FlutterPluginRegistrar) {
        FlutterEngineHolder.shared.registerPhone(messenger: registrar.messenger())
    }
}

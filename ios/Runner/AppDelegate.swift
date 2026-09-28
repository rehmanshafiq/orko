import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Called once the phone UI's engine (created by the Main storyboard's
  /// FlutterViewController in PhoneSceneDelegate's window) exists. Under the
  /// scene lifecycle there is no window yet in didFinishLaunching, so plugin and
  /// channel registration live here instead.
  ///
  /// Only the phone engine is "implicit": the CarPlay engine is created
  /// explicitly by CarPlaySceneDelegate, so this never runs for it and the
  /// phone messenger below can never be overwritten by CarPlay.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Capture the phone engine's messenger for native channels (see
    // FlutterEngineHolder). Must precede setupLiveChargingChannel().
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: PhoneEngineMessengerPlugin.key) {
      PhoneEngineMessengerPlugin.register(with: registrar)
    }

    // Register the Live Activity MethodChannel. Defined in an AppDelegate
    // extension in LiveChargingActivityManager.swift (Runner target).
    setupLiveChargingChannel()
  }
}

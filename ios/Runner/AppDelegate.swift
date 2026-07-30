import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsApiKey.isEmpty {
      GMSServices.provideAPIKey(mapsApiKey)
    }
    GeneratedPluginRegistrant.register(with: self)

    // Register the Live Activity MethodChannel. Defined in an AppDelegate
    // extension in LiveChargingActivityManager.swift (Runner target).
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupLiveChargingChannel()
    return launched
  }
}

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

    // Live Activity setup (opt-in): after completing the one-time Xcode setup in
    // ios/LIVE_ACTIVITY_SETUP.md, uncomment the next line. It lives in an
    // AppDelegate extension in LiveChargingActivityManager.swift, which is only
    // compiled once that file is added to the Runner target — so the app builds
    // unchanged until then.
    // setupLiveChargingChannel()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

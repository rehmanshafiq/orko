import CarPlay
import UIKit

/// Starts turn-by-turn navigation to a station by handing off to a CarPlay
/// navigation app — the counterpart of CarNavigation.kt, which fires
/// CarContext.ACTION_NAVIGATE at the car's default nav app. iOS has no generic
/// "default nav app" hand-off, so this tries Google Maps first and falls back
/// to Apple Maps. HUBCO is a charging app, so we never draw our own map.
///
/// Only coordinates are passed. No PII.
@MainActor
enum CarNavigation {

    /// Launches navigation to [lat]/[lng]. Shows a toast if no app accepted it.
    /// Never throws. Must be triggered by an explicit user tap.
    static func navigateTo(
        screenManager: CarScreenManager?,
        lat: Double,
        lng: Double,
        label: String
    ) {
        guard let screenManager else { return }
        let scene = screenManager.scene
        let coords = String(format: "%.6f,%.6f", locale: Locale(identifier: "en_US_POSIX"), lat, lng)

        let apple = url("maps://", ["daddr": coords, "dirflg": "d"])
        let google = url("comgooglemaps://", ["daddr": coords, "directionsmode": "driving"])

        let openApple = {
            guard let apple else { return failed(screenManager) }
            scene.open(apple, options: nil) { ok in
                if !ok { MainActor.assumeIsolatedCompat { failed(screenManager) } }
            }
        }

        // canOpenURL needs "comgooglemaps" in LSApplicationQueriesSchemes (it is).
        if let google, UIApplication.shared.canOpenURL(google) {
            scene.open(google, options: nil) { ok in
                // Installed on the phone but unable to open on the car screen.
                if !ok { MainActor.assumeIsolatedCompat { openApple() } }
            }
        } else {
            openApple()
        }
    }

    private static func failed(_ screenManager: CarScreenManager) {
        CarToast.show("No navigation app available", on: screenManager)
    }

    /// Builds the URL with percent-encoded query items, so no text can alter it.
    private static func url(_ base: String, _ query: [String: String]) -> URL? {
        var c = URLComponents(string: base)
        c?.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c?.url
    }
}

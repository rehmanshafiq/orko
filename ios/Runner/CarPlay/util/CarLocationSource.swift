import CoreLocation

/// Permission-guarded, coarse wrapper over CLLocationManager for the car
/// screens — the counterpart of CarLocationSource.kt.
///
/// The car app needs a location to decide when the driver has moved far enough
/// that the nearby-station pins are stale. Station queries themselves still go
/// through the Dart bridge, which resolves its own position when none is
/// supplied.
///
/// It never prompts: the car cannot show a permission dialog, so it relies on
/// the permission already granted to the phone app. Updates are deliberately
/// slow and coarse (see [minTime] / [minDistance]), matching Android.
final class CarLocationSource: NSObject, CLLocationManagerDelegate {

    private static let minTime: TimeInterval = 30
    private static let minDistance: CLLocationDistance = 250

    private let manager = CLLocationManager()
    private var onLocation: ((CLLocation) -> Void)?
    private var lastDelivered: Date?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = Self.minDistance
    }

    /// True when the phone app has location permission.
    func hasPermission() -> Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    /// Best cached fix, or nil.
    func lastKnown() -> CLLocation? {
        hasPermission() ? manager.location : nil
    }

    /// Starts coarse updates. No-op without permission or when already started.
    func start(_ onLocation: @escaping (CLLocation) -> Void) {
        guard self.onLocation == nil, hasPermission() else { return }
        self.onLocation = onLocation
        manager.startUpdatingLocation()
    }

    /// Stops updates. Idempotent.
    func stop() {
        guard onLocation != nil else { return }
        onLocation = nil
        lastDelivered = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fix = locations.last, let onLocation else { return }
        // Android's requestLocationUpdates(minTime = 30 s) equivalent.
        if let last = lastDelivered, Date().timeIntervalSince(last) < Self.minTime { return }
        lastDelivered = Date()
        onLocation(fix)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

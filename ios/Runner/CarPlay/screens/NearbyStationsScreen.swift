import CarPlay
import MapKit

/// Root authenticated screen: nearby charging stations as pins on the car's map
/// surface, backed by live data via [FlutterAutoBridge]. Counterpart of
/// NearbyStationsScreen.kt.
///
/// MAP SURFACE: a CPPointOfInterestTemplate — the system draws the map and the
/// pins; the app never touches MapKit rendering. It is the charging-category
/// equivalent of Android's PlaceListMapTemplate (CPMapTemplate is restricted to
/// navigation apps, just as Android's MapTemplate is).
///
/// PINS: unlike Android, CarPlay pins ARE tap targets. Tapping a pin or its
/// list row opens the system detail card, whose buttons are "Details" (pushes
/// StationDetailScreen) and "Navigate" (the Android row's nav icon).
///
/// The Charging / Trips action-strip entries are nav-bar buttons.
///
/// LOADING / ERRORS: CarPlay has no loading overlay for this template, so the
/// first load and error/empty states swap the root to a message template;
/// later reloads (returning from a pushed screen, driving 500 m) refresh the
/// pins quietly in place.
final class NearbyStationsScreen: CarScreen, CPPointOfInterestTemplateDelegate {

    private static let title = "Nearby stations"
    // CarPlay's documented cap for CPPointOfInterestTemplate.
    private static let maxMarkers = 12
    // Metres the driver must travel before the pins are re-queried.
    private static let reloadDistance: CLLocationDistance = 500

    private let locationSource = CarLocationSource()
    private var loadTask: Task<Void, Never>?

    private var loading = true
    private var errorCode: String?
    private var stations: [AutoStation] = []

    /// Last fix we have; drives the staleness check.
    private var location: CLLocation?
    /// Where the currently displayed markers were queried from.
    private var queriedFrom: CLLocation?

    private let messageTemplate: CPInformationTemplate
    private let mapTemplate: CPPointOfInterestTemplate

    init(bridge: FlutterAutoBridge) {
        messageTemplate = CPInformationTemplate(title: Self.title, layout: .leading, items: [], actions: [])
        mapTemplate = CPPointOfInterestTemplate(title: Self.title, pointsOfInterest: [], selectedIndex: NSNotFound)
        ErrorScreens.applyLoading(to: messageTemplate, title: Self.title)
        super.init(bridge: bridge, template: messageTemplate)
        mapTemplate.pointOfInterestDelegate = self
        mapTemplate.leadingNavigationBarButtons = [
            CPBarButton(title: "Charging") { [weak self] _ in
                guard let self else { return }
                self.screenManager?.push(ChargingStatusScreen(bridge: self.bridge))
            },
        ]
        mapTemplate.trailingNavigationBarButtons = [
            CPBarButton(title: "Trips") { [weak self] _ in
                guard let self else { return }
                self.screenManager?.push(SavedTripsScreen(bridge: self.bridge))
            },
        ]
    }

    override func onStart() {
        location = locationSource.lastKnown() ?? location
        render()
        load()
        locationSource.start { [weak self] fix in
            MainActor.assumeIsolatedCompat { self?.onLocationChanged(fix) }
        }
    }

    override func onStop() {
        locationSource.stop()
    }

    override func onDestroy() {
        locationSource.stop()
    }

    /// Re-queries only once the driver has left the area the pins were fetched
    /// for, so a moving car does not redraw identical markers constantly.
    private func onLocationChanged(_ fix: CLLocation) {
        location = fix
        if let from = queriedFrom, from.distance(from: fix) < Self.reloadDistance { return }
        load()
    }

    private func load() {
        loadTask?.cancel()
        loading = true
        errorCode = nil
        render()
        let from = location
        loadTask = launch { [weak self] in
            guard let self else { return }
            let result = await self.bridge.getNearbyStations(
                lat: from?.coordinate.latitude,
                lng: from?.coordinate.longitude
            )
            if Task.isCancelled { return }
            if result["ok"] as? Bool == true {
                // Markers are labelled 1..N by distance, so the pin numbering has
                // to match the row order.
                self.stations = AutoStation.listFrom(result)
                    .sorted { ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude) }
                self.queriedFrom = from
                self.errorCode = nil
            } else {
                let code = result["error"] as? String ?? "server"
                if code == "auth" {
                    // Signed out: route to the sign-in prompt instead of a map.
                    self.loading = false
                    self.screenManager?.push(SignInRequiredScreen(bridge: self.bridge))
                    return
                }
                self.errorCode = code
            }
            self.loading = false
            self.render()
        }
    }

    /// Android: onGetTemplate().
    private func render() {
        if loading {
            // Quiet refresh once the map is up; message template before that.
            if template !== mapTemplate { ErrorScreens.applyLoading(to: messageTemplate, title: Self.title) }
            return
        }

        if let code = errorCode {
            ErrorScreens.apply(to: messageTemplate, code: code, title: Self.title) { [weak self] in self?.load() }
            show(messageTemplate)
            return
        }

        if stations.isEmpty {
            ErrorScreens.apply(to: messageTemplate, title: Self.title, message: "No stations nearby") { [weak self] in
                self?.load()
            }
            show(messageTemplate)
            return
        }

        // No clustering exists in the template model, and the system caps how
        // many places it will draw, so the nearest N win and the rest are hidden.
        let pois = stations.prefix(Self.maxMarkers).enumerated().map { pointOfInterest(index: $0.offset, st: $0.element) }
        mapTemplate.setPointsOfInterest(pois, selectedIndex: NSNotFound)
        show(mapTemplate)
    }

    private func show(_ t: CPTemplate) {
        // Swapping the root is only safe while this screen is the visible one;
        // a covered screen re-renders on its next onStart.
        guard isStarted else { return }
        replaceTemplate(t)
    }

    /// One station as a pin + list row + detail card.
    private func pointOfInterest(index: Int, st: AutoStation) -> CPPointOfInterest {
        let coordinate = CLLocationCoordinate2D(latitude: st.lat ?? 0, longitude: st.lng ?? 0)
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        let name = st.name.isEmpty ? "Charging station" : st.name
        item.name = name
        let status = statusLine(st)
        let address = st.address.isEmpty ? nil : st.address

        let poi = CPPointOfInterest(
            location: item,
            title: name,
            subtitle: status,
            summary: address,
            detailTitle: name,
            detailSubtitle: status,
            detailSummary: address,
            pinImage: StationPin.image(label: String(index + 1), color: markerColor(st))
        )
        poi.primaryButton = CPTextButton(title: "Details", textStyle: .normal) { [weak self] _ in
            self?.openDetail(st)
        }
        if let lat = st.lat, let lng = st.lng, !(lat == 0 && lng == 0) {
            poi.secondaryButton = CPTextButton(title: "Navigate", textStyle: .confirm) { [weak self] _ in
                CarNavigation.navigateTo(screenManager: self?.screenManager, lat: lat, lng: lng, label: st.name)
            }
        }
        return poi
    }

    /// Green when something is free to plug into, red when nothing is.
    private func markerColor(_ st: AutoStation) -> UIColor {
        if let free = st.availableConnectors { return free > 0 ? .systemGreen : .systemRed }
        return st.available ? .systemGreen : .systemGray
    }

    /// "3.1 km · 1/2 · DC" (the distance in the driver's own unit system).
    private func statusLine(_ st: AutoStation) -> String {
        var parts: [String] = []
        if let km = st.distanceKm { parts.append(CarFormat.distance(km: km)) }
        if let total = st.numberOfConnectors { parts.append("\(st.availableConnectors ?? 0)/\(total)") }
        if !st.connectorTypes.isEmpty { parts.append(st.connectorTypes.joined(separator: "/")) }
        return parts.isEmpty ? st.address : parts.joined(separator: " · ")
    }

    private func openDetail(_ st: AutoStation) {
        screenManager?.push(StationDetailScreen(
            bridge: bridge,
            stationId: st.id,
            lat: st.lat ?? 0,
            lng: st.lng ?? 0,
            name: st.name
        ))
    }

    // MARK: CPPointOfInterestTemplateDelegate

    /// Required by the protocol. Android does not re-query on map pan either;
    /// reloads are driven by the driver's position only.
    nonisolated func pointOfInterestTemplate(_ template: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {}
}

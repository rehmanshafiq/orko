import CarPlay

/// Read-only saved-trip detail in a CPInformationTemplate (Android:
/// PaneTemplate): a summary item plus one item per charging stop, backed by
/// live data via [FlutterAutoBridge]. Counterpart of TripDetailScreen.kt.
///
/// "Navigate to next stop" hands off to a nav app (single destination —
/// multi-stop journeys stay mobile-only). No create / edit / delete controls.
final class TripDetailScreen: CarScreen {

    // CarPlay's cap on information-template items (Android: pane row limit).
    private static let maxItems = 10

    private let tripId: Int
    private let titleHint: String

    private let info: CPInformationTemplate
    private var loadTask: Task<Void, Never>?

    private var loading = true
    private var errorCode: String?
    private var trip: AutoTrip?

    init(bridge: FlutterAutoBridge, tripId: Int, titleHint: String) {
        self.tripId = tripId
        self.titleHint = titleHint
        info = CPInformationTemplate(title: titleHint.isEmpty ? "Trip" : titleHint, layout: .leading, items: [], actions: [])
        super.init(bridge: bridge, template: info)
        render()
    }

    override func onStart() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        loading = true
        errorCode = nil
        render()
        loadTask = launch { [weak self] in
            guard let self else { return }
            let result = await self.bridge.getSavedTripDetail(id: self.tripId)
            if Task.isCancelled { return }
            if result["ok"] as? Bool == true {
                self.trip = AutoTrip.detailFrom(result)
                self.errorCode = self.trip == nil ? "server" : nil
            } else {
                let code = result["error"] as? String ?? "server"
                if code == "auth" {
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

    private var title: String {
        if !titleHint.isEmpty { return titleHint }
        return trip?.title ?? "Trip"
    }

    /// Android: onGetTemplate().
    private func render() {
        if loading { return ErrorScreens.applyLoading(to: info, title: title) }

        if let code = errorCode {
            return ErrorScreens.apply(to: info, code: code, title: title) { [weak self] in self?.load() }
        }

        guard let t = trip else {
            return ErrorScreens.apply(to: info, code: "server", title: title) { [weak self] in self?.load() }
        }

        guard let firstStop = t.stops.first else {
            return ErrorScreens.apply(to: info, title: title, message: "This trip has no stops", onAction: nil)
        }

        // Summary first, then one item per charging stop.
        var items = [CPInformationItem(title: "Summary", detail: summary(t))]
        for stop in t.stops {
            items.append(CPInformationItem(
                title: "\(stop.sequence). \(stop.locationName.isEmpty ? "Stop" : stop.locationName)",
                detail: stopLine(stop)
            ))
        }

        info.title = title
        info.items = Array(items.prefix(Self.maxItems))
        // Navigate to the first stop (single destination).
        info.actions = [
            CPTextButton(title: "Navigate to next stop", textStyle: .confirm) { [weak self] _ in
                CarNavigation.navigateTo(
                    screenManager: self?.screenManager,
                    lat: firstStop.lat ?? 0,
                    lng: firstStop.lng ?? 0,
                    label: firstStop.locationName
                )
            },
        ]
    }

    private func summary(_ t: AutoTrip) -> String {
        var parts: [String] = []
        if let v = t.totalDistanceKm { parts.append("\(CarFormat.trimNum(v)) km") }
        if let v = t.totalDriveMinutes { parts.append("\(CarFormat.trimNum(v)) min drive") }
        if let v = t.totalChargingMinutes { parts.append("\(CarFormat.trimNum(v)) min charging") }
        if let v = t.totalCost { parts.append("\(CarFormat.trimNum(v)) \(t.currency)".trimmingCharacters(in: .whitespaces)) }
        return parts.isEmpty ? "\(t.stopCount) stops" : parts.joined(separator: " · ")
    }

    private func stopLine(_ stop: AutoTripStop) -> String {
        var parts: [String] = []
        if let a = stop.arrivalSoc, let d = stop.departureSoc {
            parts.append("SoC \(CarFormat.trimNum(a))%→\(CarFormat.trimNum(d))%")
        }
        if let m = stop.chargingMinutes { parts.append("\(CarFormat.trimNum(m)) min") }
        var connector = stop.connectorType.trimmingCharacters(in: .whitespaces).isEmpty ? "" : stop.connectorType
        if let kw = stop.powerKw {
            if !connector.isEmpty { connector += " " }
            connector += "\(CarFormat.trimNum(kw)) kW"
        }
        if !connector.isEmpty { parts.append(connector) }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}

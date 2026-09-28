import CarPlay

/// Station details in a driver-safe CPInformationTemplate (Android:
/// PaneTemplate), backed by live data via [FlutterAutoBridge]. Shows status +
/// hours, address, pricing, contact, connectors and rating, plus a Navigate
/// action. Counterpart of StationDetailScreen.kt.
final class StationDetailScreen: CarScreen {

    // CarPlay's cap on information-template items (Android: pane row limit).
    private static let maxItems = 10
    // Contact numbers shown (Android: row text lines the host renders).
    private static let maxContactNumbers = 2

    private let stationId: String
    private let lat: Double
    private let lng: Double
    private let name: String

    private let info: CPInformationTemplate
    private var loadTask: Task<Void, Never>?

    private var loading = true
    private var errorCode: String?
    private var detail: AutoStationDetail?

    init(bridge: FlutterAutoBridge, stationId: String, lat: Double, lng: Double, name: String) {
        self.stationId = stationId
        self.lat = lat
        self.lng = lng
        self.name = name
        info = CPInformationTemplate(title: name.isEmpty ? "Station" : name, layout: .leading, items: [], actions: [])
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
            let result = await self.bridge.getStationDetail(id: self.stationId, lat: self.lat, lng: self.lng)
            if Task.isCancelled { return }
            if result["ok"] as? Bool == true {
                self.detail = AutoStationDetail.from(result)
                self.errorCode = self.detail == nil ? "server" : nil
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
        if !name.isEmpty { return name }
        return detail?.name ?? "Station"
    }

    /// Android: onGetTemplate().
    private func render() {
        if loading {
            // Navigate is offered before the detail fetch finishes: the row that
            // pushed this screen already supplied the coordinates, so a driver
            // who only wants directions never waits on the network.
            ErrorScreens.applyLoading(to: info, title: title, actions: navigateAction().map { [$0] } ?? [])
            return
        }

        if let code = errorCode {
            ErrorScreens.apply(to: info, code: code, title: title) { [weak self] in self?.load() }
            return
        }

        guard let d = detail else {
            ErrorScreens.apply(to: info, code: "server", title: title) { [weak self] in self?.load() }
            return
        }

        // Candidate items in priority order, then capped to the template limit.
        var items: [CPInformationItem] = []

        var status = d.open ? "Open" : "Closed"
        if !d.hoursLabel.isEmpty { status += " · \(d.hoursLabel)" }
        items.append(CPInformationItem(title: "Status", detail: status))

        if !d.address.trimmingCharacters(in: .whitespaces).isEmpty {
            items.append(CPInformationItem(title: "Address", detail: d.address))
        }

        // Pricing as its own section (uniform across connectors).
        if let price = d.connectors.lazy.map(\.priceDisplay).first(where: { !$0.isEmpty }) {
            items.append(CPInformationItem(title: "Pricing", detail: price))
        }

        if !d.contactNumbers.isEmpty {
            items.append(CPInformationItem(
                title: "Contact No.",
                detail: d.contactNumbers.prefix(Self.maxContactNumbers).joined(separator: "\n")
            ))
        }

        if !d.connectors.isEmpty {
            // Section heading for the charger list; each port shows only its state.
            items.append(CPInformationItem(title: "Charger Ports", detail: nil))
            for c in d.connectors {
                let state = c.stateDisplay.trimmingCharacters(in: .whitespaces)
                items.append(CPInformationItem(title: c.header, detail: state.isEmpty ? "—" : c.stateDisplay))
            }
        }

        if let rating = d.averageRating, rating > 0 {
            items.append(CPInformationItem(title: "Rating", detail: String(format: "%.1f", rating)))
        }

        info.title = title
        info.items = Array(items.prefix(Self.maxItems))
        info.actions = navigateAction().map { [$0] } ?? []
    }

    /// The Navigate action, or nil when we have no usable coordinates —
    /// handing a maps app 0,0 would send the driver to the Atlantic.
    private func navigateAction() -> CPTextButton? {
        // Prefer the detail's own coordinates; fall back to the ones passed in.
        let navLat = detail?.lat ?? lat
        let navLng = detail?.lng ?? lng
        if navLat == 0 && navLng == 0 { return nil }
        let label = name.isEmpty ? (detail?.name ?? "") : name
        return CPTextButton(title: "Navigate", textStyle: .confirm) { [weak self] _ in
            CarNavigation.navigateTo(screenManager: self?.screenManager, lat: navLat, lng: navLng, label: label)
        }
    }
}

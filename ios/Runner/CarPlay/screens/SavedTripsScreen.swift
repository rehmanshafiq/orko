import CarPlay

/// Read-only list of the user's saved trips (Android: ListTemplate), backed by
/// live data via [FlutterAutoBridge]. Tapping a trip opens [TripDetailScreen].
/// No create / edit / delete — planning stays on the phone. Counterpart of
/// SavedTripsScreen.kt.
///
/// Loading / error / empty states use the list's own empty-state text, with a
/// "Retry" nav-bar button where Android's MessageTemplate had a Retry action.
final class SavedTripsScreen: CarScreen {

    private static let title = "My trips"

    private let list: CPListTemplate
    private var loadTask: Task<Void, Never>?

    private var loading = true
    private var errorCode: String?
    private var trips: [AutoTrip] = []

    init(bridge: FlutterAutoBridge) {
        list = CPListTemplate(title: Self.title, sections: [])
        super.init(bridge: bridge, template: list)
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
            let result = await self.bridge.getSavedTrips()
            if Task.isCancelled { return }
            if result["ok"] as? Bool == true {
                self.trips = AutoTrip.listFrom(result)
                self.errorCode = nil
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

    /// Android: onGetTemplate().
    private func render() {
        if loading { return showMessage("Loading…", retry: false) }
        if let code = errorCode { return showMessage(ErrorScreens.copyForCode(code), retry: true) }
        if trips.isEmpty { return showMessage("No saved trips", retry: true) }

        let items: [CPListItem] = trips.prefix(rowLimit()).map { trip in
            let item = CPListItem(text: trip.title.isEmpty ? "Trip #\(trip.id)" : trip.title, detailText: subtitle(trip))
            item.accessoryType = .disclosureIndicator
            item.handler = { [weak self] _, completion in
                self?.openDetail(trip)
                completion()
            }
            return item
        }
        list.trailingNavigationBarButtons = []
        list.updateSections([CPListSection(items: items)])
    }

    private func showMessage(_ message: String, retry: Bool) {
        list.updateSections([])
        list.emptyViewTitleVariants = [message]
        list.trailingNavigationBarButtons = retry
            ? [CPBarButton(title: "Retry") { [weak self] _ in self?.load() }]
            : []
    }

    private func subtitle(_ trip: AutoTrip) -> String {
        var parts: [String] = []
        if let km = trip.totalDistanceKm { parts.append("\(CarFormat.trimNum(km)) km") }
        parts.append("\(trip.stopCount) stops")
        if let cost = trip.totalCost {
            parts.append("\(CarFormat.trimNum(cost)) \(trip.currency)".trimmingCharacters(in: .whitespaces))
        }
        return parts.joined(separator: " · ")
    }

    private func openDetail(_ trip: AutoTrip) {
        screenManager?.push(TripDetailScreen(bridge: bridge, tripId: trip.id, titleHint: trip.title))
    }

    /// The car's list limit (Android: ConstraintManager CONTENT_LIMIT_TYPE_LIST).
    private func rowLimit() -> Int { max(1, Int(CPListTemplate.maximumItemCount)) }
}

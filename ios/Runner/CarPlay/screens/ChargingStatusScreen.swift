import CarPlay

/// Read-only live charging telemetry in a CPInformationTemplate (Android:
/// PaneTemplate), refreshed on a modest timer ONLY while the screen is visible
/// (started on onStart, cancelled on onStop) to conserve battery/data.
/// Counterpart of ChargingStatusScreen.kt.
///
/// There is intentionally NO start/stop control — the backend exposes no
/// stop-charging endpoint and it would be unsafe while driving.
final class ChargingStatusScreen: CarScreen {

    private static let title = "Active charging"
    private static let pollInterval: UInt64 = 15_000_000_000
    private static let maxItems = 4

    private let info: CPInformationTemplate
    private var pollTask: Task<Void, Never>?

    private var firstLoad = true
    private var errorCode: String?
    private var active = false
    private var session: AutoLiveSession?

    init(bridge: FlutterAutoBridge) {
        info = CPInformationTemplate(title: Self.title, layout: .leading, items: [], actions: [])
        super.init(bridge: bridge, template: info)
        render()
    }

    override func onStart() {
        startPolling()
    }

    override func onStop() {
        stopPolling()
    }

    private func startPolling() {
        if let pollTask, !pollTask.isCancelled { return }
        pollTask = launch { [weak self] in
            while !Task.isCancelled {
                await self?.tick()
                try? await Task.sleep(nanoseconds: Self.pollInterval)
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func tick() async {
        let result = await bridge.getLiveSession()
        if Task.isCancelled { return }
        if result["ok"] as? Bool == true {
            active = result["active"] as? Bool == true
            session = active ? AutoLiveSession.from(result) : nil
            errorCode = nil
        } else {
            let code = result["error"] as? String ?? "server"
            if code == "auth" {
                stopPolling()
                firstLoad = false
                screenManager?.push(SignInRequiredScreen(bridge: bridge))
                return
            }
            errorCode = code
        }
        firstLoad = false
        render()
    }

    /// Android: onGetTemplate().
    private func render() {
        if firstLoad {
            ErrorScreens.applyLoading(to: info, title: Self.title)
            return
        }

        if let code = errorCode { return renderError(code) }

        if !active {
            ErrorScreens.apply(to: info, title: Self.title, message: "No active charging session", onAction: nil)
            return
        }

        guard let s = session else { return renderError("server") }
        var items: [CPInformationItem] = []

        if let p = s.percent {
            items.append(CPInformationItem(title: "Charge", detail: "\(CarFormat.trimNum(p))%"))
        }
        if let power = powerLabel(s) {
            items.append(CPInformationItem(title: "Power", detail: power))
        }
        if let left = s.timeLeft, !left.trimmingCharacters(in: .whitespaces).isEmpty {
            items.append(CPInformationItem(title: "Time left", detail: left))
        }
        if let cost = s.cost {
            items.append(CPInformationItem(title: "Cost", detail: CarFormat.trimNum(cost)))
        }
        if items.isEmpty {
            items.append(CPInformationItem(title: "Charging", detail: "In progress"))
        }

        let name = s.locationName?.trimmingCharacters(in: .whitespaces) ?? ""
        info.title = name.isEmpty ? Self.title : name
        info.items = Array(items.prefix(Self.maxItems))
        info.actions = []
    }

    private func powerLabel(_ s: AutoLiveSession) -> String? {
        var parts: [String] = []
        if let kw = s.speedKw { parts.append("\(CarFormat.trimNum(kw)) kW") }
        if let kwh = s.energyKwh { parts.append("\(CarFormat.trimNum(kwh)) kWh") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func renderError(_ code: String) {
        ErrorScreens.apply(to: info, code: code, title: Self.title) { [weak self] in
            guard let self else { return }
            self.firstLoad = true
            self.render()
            self.startPolling()
        }
    }
}

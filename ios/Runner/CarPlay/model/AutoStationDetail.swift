import Foundation

/// Sanitized, display-only station detail from the Dart bridge
/// (`getStationDetail`). Public station info only — no user PII.
struct AutoStationDetail {
    let id: String
    let name: String
    let address: String
    let open: Bool
    let openingTime: String
    let closingTime: String
    let distanceKm: Double?
    let connectors: [AutoConnector]
    let averageRating: Double?
    let contactNumber: String
    let lat: Double?
    let lng: Double?

    /// Contact number(s), each normalized with a leading 0. The backend may pack
    /// more than one number separated by a literal "\n", a real newline, or a
    /// comma/semicolon — each is returned as its own entry.
    var contactNumbers: [String] {
        contactNumber
            .replacingOccurrences(of: "\\n", with: "\n")
            .components(separatedBy: CharacterSet(charactersIn: "\n,;"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.hasPrefix("0") || $0.hasPrefix("+") ? $0 : "0\($0)" }
    }

    /// Human hours label, e.g. "9:00 AM - 10:00 PM", "24 hours", or empty.
    var hoursLabel: String {
        let o = openingTime.trimmingCharacters(in: .whitespaces)
        let c = closingTime.trimmingCharacters(in: .whitespaces)
        if o.isEmpty || c.isEmpty { return "" }
        if Self.isAllDay(o, c) { return "24 hours" }
        return "\(Self.to12Hour(o)) - \(Self.to12Hour(c))"
    }

    /// Converts "HH:mm[:ss]" to a 12-hour clock label, e.g. "22:00:00" → "10:00 PM".
    private static func to12Hour(_ raw: String) -> String {
        let parts = raw.split(separator: ":")
        guard let first = parts.first, let h = Int(first) else { return raw }
        let m = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        let period = h < 12 ? "AM" : "PM"
        let hour12 = h % 12 == 0 ? 12 : h % 12
        return String(format: "%d:%02d %@", hour12, m, period)
    }

    /// True when the open/close times span the whole day (e.g. 00:00–23:59).
    private static func isAllDay(_ o: String, _ c: String) -> Bool {
        let opensAtMidnight = o == "00:00" || o == "0:00" || o.hasPrefix("00:00:00")
        let closesEndOfDay = c == "23:59" || c == "24:00" ||
            c.hasPrefix("23:59:59") || c.hasPrefix("24:00:00") ||
            c.hasPrefix("00:00:00") || c == "00:00"
        return opensAtMidnight && closesEndOfDay
    }

    static func from(_ result: [String: Any]) -> AutoStationDetail? {
        guard let m = ChannelValue.map(result["station"]) else { return nil }
        return AutoStationDetail(
            id: ChannelValue.text(m["id"]) ?? "",
            name: ChannelValue.string(m["name"]) ?? "",
            address: ChannelValue.string(m["address"]) ?? "",
            open: ChannelValue.bool(m["open"]) ?? false,
            openingTime: ChannelValue.string(m["openingTime"]) ?? "",
            closingTime: ChannelValue.string(m["closingTime"]) ?? "",
            distanceKm: ChannelValue.double(m["distanceKm"]),
            connectors: (ChannelValue.list(m["connectors"]) ?? [])
                .compactMap(ChannelValue.map).map(AutoConnector.from),
            averageRating: ChannelValue.double(m["averageRating"]),
            contactNumber: ChannelValue.string(m["contactNumber"]) ?? "",
            lat: ChannelValue.double(m["lat"]),
            lng: ChannelValue.double(m["lng"])
        )
    }
}

/// A single connector on a station (display-only).
struct AutoConnector {
    let type: String
    let powerKw: String
    let priceLabel: String
    let state: String

    /// e.g. "DC 60 kW" (falls back gracefully when fields are missing).
    var header: String {
        var parts: [String] = []
        if !type.trimmingCharacters(in: .whitespaces).isEmpty { parts.append(type) }
        if !powerKw.trimmingCharacters(in: .whitespaces).isEmpty { parts.append("\(powerKw) kW") }
        return parts.isEmpty ? "Connector" : parts.joined(separator: " ")
    }

    /// Display state: the backend's "Charging" is shown as "Occupied".
    var stateDisplay: String {
        state.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare("charging") == .orderedSame
            ? "Occupied" : state
    }

    /// Price shown as "PKR 120 per kWh" (raw label uses a "/kwh" suffix).
    var priceDisplay: String {
        priceLabel
            .replacingOccurrences(of: "/\\s*kwh", with: " per kWh", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "/\\s*kw\\b", with: " per kW", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
    }

    static func from(_ m: [String: Any]) -> AutoConnector {
        AutoConnector(
            type: ChannelValue.string(m["type"]) ?? "",
            powerKw: ChannelValue.text(m["powerKw"]) ?? "",
            priceLabel: ChannelValue.string(m["priceLabel"]) ?? "",
            state: ChannelValue.string(m["state"]) ?? ""
        )
    }
}

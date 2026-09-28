import Foundation

/// Lenient readers for platform-channel values (NSNumber / NSString / arrays),
/// matching the Kotlin `as? Number` / `as? String` casts in the Android models.
enum ChannelValue {
    static func double(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
    static func int(_ v: Any?) -> Int? { (v as? NSNumber)?.intValue }
    static func string(_ v: Any?) -> String? { v as? String }
    static func bool(_ v: Any?) -> Bool? { (v as? NSNumber)?.boolValue }
    static func map(_ v: Any?) -> [String: Any]? { v as? [String: Any] }
    static func list(_ v: Any?) -> [Any]? { v as? [Any] }

    /// Kotlin `m["id"]?.toString()`: numbers and strings both become text.
    static func text(_ v: Any?) -> String? {
        switch v {
        case let s as String: return s
        case let n as NSNumber: return n.stringValue
        default: return nil
        }
    }
}

/// Sanitized, display-only station data received from the Dart bridge
/// (`getNearbyStations`). Public station info only — no user PII.
struct AutoStation {
    let id: String
    let name: String
    let address: String
    let distanceKm: Double?
    let available: Bool
    let availableConnectors: Int?
    let numberOfConnectors: Int?
    let connectorTypes: [String]
    let powerKw: [Double]
    let priceLabel: String
    let lat: Double?
    let lng: Double?

    static func from(_ m: [String: Any]) -> AutoStation {
        AutoStation(
            id: ChannelValue.text(m["id"]) ?? "",
            name: ChannelValue.string(m["name"]) ?? "",
            address: ChannelValue.string(m["address"]) ?? "",
            distanceKm: ChannelValue.double(m["distanceKm"]),
            available: ChannelValue.bool(m["available"]) ?? false,
            availableConnectors: ChannelValue.int(m["availableConnectors"]),
            numberOfConnectors: ChannelValue.int(m["numberOfConnectors"]),
            connectorTypes: ChannelValue.list(m["connectorTypes"])?.compactMap { $0 as? String } ?? [],
            powerKw: ChannelValue.list(m["powerKw"])?.compactMap(ChannelValue.double) ?? [],
            priceLabel: ChannelValue.string(m["priceLabel"]) ?? "",
            lat: ChannelValue.double(m["lat"]),
            lng: ChannelValue.double(m["lng"])
        )
    }

    /// Parses the `stations` array out of a `getNearbyStations` result map.
    static func listFrom(_ result: [String: Any]) -> [AutoStation] {
        (ChannelValue.list(result["stations"]) ?? []).compactMap(ChannelValue.map).map(from)
    }
}

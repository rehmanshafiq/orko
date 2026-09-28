import Foundation

/// Sanitized, display-only live charging telemetry from the Dart bridge
/// (`getLiveSession`). Telemetry only — no payment details or PII.
struct AutoLiveSession {
    let locationName: String?
    let percent: Double?
    let speedKw: Double?
    let energyKwh: Double?
    let timeLeft: String?
    let cost: Double?

    /// Parses the `session` object out of a `getLiveSession` result map.
    static func from(_ result: [String: Any]) -> AutoLiveSession? {
        guard let m = ChannelValue.map(result["session"]) else { return nil }
        return AutoLiveSession(
            locationName: ChannelValue.string(m["locationName"]),
            percent: ChannelValue.double(m["percent"]),
            speedKw: ChannelValue.double(m["speedKw"]),
            energyKwh: ChannelValue.double(m["energyKwh"]),
            timeLeft: ChannelValue.string(m["timeLeft"]),
            cost: ChannelValue.double(m["cost"])
        )
    }
}

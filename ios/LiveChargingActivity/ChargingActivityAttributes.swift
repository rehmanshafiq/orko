import ActivityKit
import Foundation

/// Shared attributes + dynamic state for the live-charging Live Activity.
///
/// IMPORTANT: this file must belong to **both** targets — the `Runner` app
/// (which starts/updates/ends the activity from `LiveChargingActivityManager`)
/// and the `LiveChargingActivity` widget extension (which renders it). Set both
/// checkboxes under *Target Membership* in Xcode's File Inspector.
@available(iOS 16.1, *)
struct ChargingActivityAttributes: ActivityAttributes {
    public typealias ContentState = LiveState

    /// Dynamic, updated on every poll tick from Flutter.
    public struct LiveState: Codable, Hashable {
        var station: String
        var percentLabel: String   // e.g. "62%"
        var percentValue: Double   // 0...100, drives the progress bar
        var energy: String         // e.g. "3.4 kWh"
        var time: String           // e.g. "0h 12m"
        var cost: String           // e.g. "PKR 120"
        var isCompleted: Bool
    }

    /// Static for the life of the activity.
    var title: String
}

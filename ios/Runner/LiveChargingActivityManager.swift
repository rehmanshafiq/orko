import ActivityKit
import Flutter
import Foundation
import UIKit

/// Bridges the `orko/live_charging_activity` MethodChannel to the native Live
/// Activity manager. Call `setupLiveChargingChannel()` from
/// `AppDelegate.application(_:didFinishLaunchingWithOptions:)` after completing
/// the Xcode setup (see ios/LIVE_ACTIVITY_SETUP.md). Kept here — not in
/// AppDelegate — so the Runner target builds unchanged until this file is added.
extension AppDelegate {
    func setupLiveChargingChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController
        else { return }
        let channel = FlutterMethodChannel(
            name: "orko/live_charging_activity",
            binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            guard #available(iOS 16.1, *) else {
                result(call.method == "isSupported" ? false : nil)
                return
            }
            let args = call.arguments as? [String: String]
            switch call.method {
            case "isSupported":
                result(LiveChargingActivityManager.isSupported())
            case "start":
                LiveChargingActivityManager.start(args ?? [:])
                result(nil)
            case "update":
                LiveChargingActivityManager.update(args ?? [:])
                result(nil)
            case "end":
                LiveChargingActivityManager.end(args)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}

/// Starts / updates / ends the live-charging Live Activity from the app in
/// response to MethodChannel calls. Belongs to the `Runner` target only. Gated
/// to iOS 16.1+ — older systems get a graceful no-op and `isSupported()`
/// returns false so Flutter skips the whole feature.
@available(iOS 16.1, *)
enum LiveChargingActivityManager {

    private static var activity: Activity<ChargingActivityAttributes>?

    static func isSupported() -> Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start(_ args: [String: String]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        // Already running — just update it.
        if activity != nil {
            update(args)
            return
        }
        let attributes = ChargingActivityAttributes(station: args)
        let state = ChargingActivityAttributes.LiveState(fromFlutter: args)
        do {
            activity = try Activity.request(
                attributes: attributes,
                contentState: state,
                pushType: nil
            )
        } catch {
            NSLog("[LiveActivity] start failed: \(error)")
        }
    }

    static func update(_ args: [String: String]) {
        guard let activity = activity else { return }
        let state = ChargingActivityAttributes.LiveState(fromFlutter: args)
        Task { await activity.update(using: state) }
    }

    static func end(_ args: [String: String]?) {
        guard let activity = activity else { return }
        let finalState = ChargingActivityAttributes.LiveState(
            fromFlutter: args ?? [:],
            completedFallback: true
        )
        Task {
            await activity.end(using: finalState, dismissalPolicy: .default)
        }
        self.activity = nil
    }
}

// MARK: - Mapping from the Flutter [String: String] payload

@available(iOS 16.1, *)
private extension ChargingActivityAttributes {
    init(station args: [String: String]) {
        self.init(title: args["station"] ?? "Charging Session")
    }
}

@available(iOS 16.1, *)
private extension ChargingActivityAttributes.LiveState {
    init(fromFlutter args: [String: String], completedFallback: Bool = false) {
        self.init(
            station: args["station"] ?? "Charging Session",
            percentLabel: args["percent"]?.isEmpty == false ? args["percent"]! : "—",
            percentValue: Double(args["percentValue"] ?? "") ?? 0,
            energy: args["energy"]?.isEmpty == false ? args["energy"]! : "—",
            time: args["time"]?.isEmpty == false ? args["time"]! : "—",
            cost: args["cost"]?.isEmpty == false ? args["cost"]! : "—",
            isCompleted: (args["state"] == "completed") || completedFallback
        )
    }
}

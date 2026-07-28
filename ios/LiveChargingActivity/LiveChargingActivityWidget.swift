import ActivityKit
import SwiftUI
import WidgetKit

/// Widget-extension entry point. Belongs to the `LiveChargingActivity` target
/// only. If your extension already has a `@main` bundle from the Xcode template,
/// add `LiveChargingLiveActivity()` to that bundle instead of declaring a second
/// `@main` (only one `@main` is allowed per target).
@main
struct LiveChargingActivityBundle: WidgetBundle {
    var body: some Widget {
        LiveChargingLiveActivity()
    }
}

@available(iOS 16.1, *)
struct LiveChargingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChargingActivityAttributes.self) { context in
            // ── Lock screen / banner ────────────────────────────────────────
            LiveChargingLockScreenView(
                title: context.attributes.title,
                state: context.state
            )
            .padding(16)
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.percentLabel, systemImage: "bolt.fill")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.time)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.isCompleted
                             ? "Charging complete"
                             : context.attributes.title)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                        ProgressView(value: context.state.percentValue, total: 100)
                            .tint(.green)
                        HStack {
                            Text(context.state.energy)
                            Spacer()
                            Text(context.state.cost)
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                    }
                }
            } compactLeading: {
                Image(systemName: "bolt.fill").foregroundColor(.green)
            } compactTrailing: {
                Text(context.state.percentLabel).foregroundColor(.white)
            } minimal: {
                Image(systemName: "bolt.fill").foregroundColor(.green)
            }
            .widgetURL(URL(string: "orko://live"))
        }
    }
}

@available(iOS 16.1, *)
struct LiveChargingLockScreenView: View {
    let title: String
    let state: ChargingActivityAttributes.LiveState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(state.isCompleted ? "Charging Complete" : "Charging",
                      systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text(state.percentLabel)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            ProgressView(value: state.percentValue, total: 100)
                .tint(.green)

            HStack(spacing: 16) {
                metric(icon: "battery.100.bolt", value: state.energy)
                metric(icon: "clock", value: state.time)
                Spacer()
                metric(icon: "creditcard", value: state.cost)
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
        }
    }

    private func metric(icon: String, value: String) -> some View {
        Label(value, systemImage: icon)
    }
}

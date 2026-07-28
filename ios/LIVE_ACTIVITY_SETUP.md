# iOS Live Activity — Xcode setup (one-time)

The Dart + native Swift code for the live-charging Live Activity is already in the
repo. What Xcode still needs is a **Widget Extension target** to host the widget
(a target can only be created in Xcode — it can't be added reliably by editing
`project.pbxproj` by hand).

## Files already in the repo

| File | Target membership |
|------|-------------------|
| `ios/LiveChargingActivity/ChargingActivityAttributes.swift` | **Runner + LiveChargingActivity** (both) |
| `ios/LiveChargingActivity/LiveChargingActivityWidget.swift` | **LiveChargingActivity only** |
| `ios/Runner/LiveChargingActivityManager.swift` | **Runner only** |
| `ios/Runner/AppDelegate.swift` | Runner (MethodChannel already wired) |
| `ios/Runner/Info.plist` | `NSSupportsLiveActivities = true` already added |

## Steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target… → Widget Extension.**
   - Product name: `LiveChargingActivity`
   - **Tick "Include Live Activity".** Untick "Include Configuration App Intent".
   - Finish. When prompted to activate the scheme, click **Activate**.
3. Set the extension's **Minimum Deployments** to **iOS 16.1** (target → General).
   (The Runner app stays at 15.0; the activity is runtime-gated to 16.1+.)
4. Delete the two placeholder Swift files Xcode generated inside the new
   `LiveChargingActivity/` group (e.g. `LiveChargingActivity.swift` and its
   bundle) **or** remove their `@main`, so there is exactly one `@main`
   (`LiveChargingActivityBundle` in `LiveChargingActivityWidget.swift`).
5. Add the existing repo files to the new target:
   - Select `ios/LiveChargingActivity/LiveChargingActivityWidget.swift` and, in
     the File Inspector → **Target Membership**, tick **LiveChargingActivity**.
   - Select `ios/LiveChargingActivity/ChargingActivityAttributes.swift` and tick
     **BOTH** `Runner` and `LiveChargingActivity`.
   - Confirm `ios/Runner/LiveChargingActivityManager.swift` is a member of
     **Runner** only.
   (If Xcode didn't auto-add the files, drag the `ios/LiveChargingActivity`
   folder into the project first, choosing "Create groups" and the correct
   target membership.)
6. In `ios/Runner/AppDelegate.swift`, **uncomment** the
   `setupLiveChargingChannel()` line (it's already there, commented). This is the
   only AppDelegate change; until it's uncommented the app builds unchanged.
7. Build & run on a **physical device or an iOS 16.1+ simulator**.

## Verify

- Start a charging session (or send the `Live Session Started` / `Charging
  Started` push). A Live Activity should appear on the lock screen and Dynamic
  Island with station, %, energy, time and cost, updating while the app is open.
- End the session → the activity shows "Charging Complete" briefly and dismisses.
- On iOS < 16.1 the whole feature is a no-op (`isSupported` returns false).

## Notes / limitations

- **Background updates:** while the app is foregrounded the activity updates from
  the app's poll. For continuous updates while the app is **backgrounded/closed**,
  the backend must send **ActivityKit APNs pushes** to the activity's push token
  (a separate backend task). Without it, the activity holds its last values until
  the app is next active; a stop push still ends it.
- **Tap target:** tapping the activity opens the app (default). The widget also
  sets `widgetURL(orko://live)`; to route that to the Live tab, register an
  `orko` URL scheme in `Info.plist` and handle it in the router (optional).
- If App Store distribution complains about the extension's bundle id, make it
  `com.orkohubco.mobile.orkoHubco.LiveChargingActivity` (Runner bundle id +
  `.LiveChargingActivity`).

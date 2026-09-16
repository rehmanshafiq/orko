# Android Auto — Phase 12: Production Readiness & Go-Live Checklist

**Feature:** HUBCO Green Android Auto (EV charging) · **Branch:** `feature/android-auto`
**Category:** `androidx.car.app.category.POI` (EV charging; `CHARGING` is deprecated) · **Car App Library:** `androidx.car.app:app` + `app-projected` `1.4.0`
**Date:** 2026-09-15

> Owners below are role placeholders — assign real names before go-live.
> Status legend: ✅ done · 🔲 pending (manual/external) · ⚠️ needs decision.

---

## A. Code-side items (all green)

| # | Item | Status | Evidence |
|---|---|---|---|
| A1 | CarAppService declared, exported, `POI` category, `minCarApiLevel=1` | ✅ | Merged manifest verified; `CHARGING`→`POI` per Google deprecation |
| A2 | Native Car App templates only (no Flutter UI in car) | ✅ | `auto/` Kotlin package; ListTemplate/PaneTemplate/MessageTemplate |
| A3 | Data via cached FlutterEngine bridge; reuses real datasources/auth/cert-pinning | ✅ | `android_auto_bridge.dart` + `FlutterAutoBridge.kt` (Phase 2) |
| A4 | Access token never crosses the channel; only sanitized display data | ✅ | Bridge serializes display maps only; **pending formal Phase 10 sign-off** |
| A5 | Auth gate (signed-out → SignInRequiredScreen; Refresh advances) | ✅ | Phase 3 |
| A6 | Full flow: nearby → detail → navigate; charging; trips → stops → navigate | ✅ | Phases 4–7A |
| A7 | Centralized, driver-safe error/empty handling; never crashes | ✅ | `ErrorScreens.kt` (Phase 8) |
| A8 | Lifecycle: engine Session-scoped, timers visible-only, teardown idempotent + resurrection-safe | ✅ | Phase 9 |
| A9 | `flutter analyze` 0 errors, no new warnings vs baseline | ✅ | Phase 11 |
| A10 | `flutter test` — 9 real tests pass (pre-existing stub failure only) | ✅ | Phase 11 |
| A11 | Debug + release builds pass; **R8 keeps car classes** (kept in `mapping.txt`) | ✅ | Phase 11 (`app-release.aab` 63.4 MB) |
| A12 | Release signing (keystore from `android/key.properties`) | ✅ | AAB signed in release build |
| A13 | ProGuard keep rules for `androidx.car.app.**` + `auto.**` | ✅ | `proguard-rules.pro`; verified via mapping |
| A14 | No changes to `main.dart`, Cubits, repos, routing, `pubspec.yaml`, existing services | ✅ | git working-tree diff (Phase 11) |

**Owner:** Mobile eng. **Blocking go-live:** only A4's formal Phase 10 security sign-off remains (see §D).

---

## B. Play Console configuration (external — manual)

| # | Item | Status | Owner |
|---|---|---|---|
| B1 | Upload the release AAB to a test track (internal/closed) — done | ✅ | User uploaded to internal + closed testing |
| B2 | **Android Auto has NO Play Console declaration/toggle.** It is phone-projected, not a form factor. Support is declared entirely by the manifest (`CarAppService` + POI `<category>`), which the AAB already carries. Nothing to fill in. | ✅ | Manifest |
| B3 | ~~Select POI category in the console~~ — **NOT a console step.** Declared in the **manifest** (`androidx.car.app.category.POI`, done). No category dropdown exists for Car App Library apps. | ✅ | Manifest |
| B4 | ⚠️ Do **NOT** add "Android Automotive OS" under Advanced settings → Form factors. AAOS is the car's *embedded* OS — a different form factor needing a different build. This project is Android Auto (projection) only. | ✅ | — |
| B5 | Google **automatically** reviews the car app against **Car app quality** guidelines once the POI AAB is rolled out (no form triggers it). **Non-blocking on internal/closed**, **blocking on open/production**. Result by email to the developer account; a review status may also appear on the release/publishing overview. | 🔲 | Release mgr / QA |
| B6 | After approval, promote to production track (remove any rejected artifacts before resubmitting) | 🔲 | Release mgr |

> How the declaration actually works (Car App Library / templated Android Auto app):
> support is declared **only** by the **`CarAppService` + POI `<category>`
> intent-filter in the manifest**. There is **no "App content → Cars" form and no
> "Form factors → Android Auto" opt-in** — Android Auto is not a Play Console form
> factor (the Form-factors list offers Android *Automotive* OS, TV, Wear OS,
> Play Games on PC — NOT Android Auto). Publishing the POI AAB is the entire
> declaration; Google reviews it automatically.
>
> During development the car app is testable via DHU with Android Auto "Unknown
> sources" enabled (see §C) — no review needed for that.
>
> ⚠️ POI review consideration: Google's POI guidance expects a map-based experience
> and lists `<uses-permission android:name="androidx.car.app.MAP_TEMPLATES"/>` for
> the map templates. This app currently uses List/Pane/Message templates only (no
> in-car map), which is functionally valid but may draw review feedback for a POI
> app. If needed, v2 can adopt `PlaceListMapTemplate` + add that permission (see §F).

---

## C. Testing still required (external / manual)

| # | Item | Status | Owner |
|---|---|---|---|
| C1 | **Desktop Head Unit (DHU)** full matrix (Phase 11 §3) | 🔲 | QA |
| C2 | Real-vehicle test on a physical Android Auto head unit | 🔲 | QA |
| C3 | Regression pass on phone: startup, login, map, notifications, FCM, live-charging foreground service | 🔲 | QA |
| C4 | Concurrent test: car connected + phone in use + live-charging notification | 🔲 | QA |
| C5 | Repeated connect/disconnect (leak/crash check) | 🔲 | QA |

DHU quick-start: enable Developer settings in the Android Auto app → "Unknown
sources" + "Start head unit server", then run `desktop-head-unit` from the SDK's
`extras/google/auto/`. Sign in on the phone first so the car sees a session.

---

## D. Security (Phase 10 — recommended before go-live)

| # | Item | Status | Owner |
|---|---|---|---|
| D1 | Formal Phase 10 security review (token isolation, no secret logging, HostValidator, cert pinning intact) | 🔲 | Security / Mobile eng |
| D2 | Confirm release HostValidator is NOT allow-all (uses `hosts_allowlist_sample`) | ✅ | `OrkoCarAppService` gates ALLOW_ALL to `FLAG_DEBUGGABLE` |
| D3 | Grep release build for `Authorization`/`Bearer`/`access_token`/`Log.`/`print(` in `auto/` + bridge | 🔲 | Mobile eng |
| D4 | Confirm cert pinning still active in release (bundled CA present) | 🔲 | Mobile eng |

> A4 + D1 are the same sign-off. Recommend running Phase 10 before promoting to
> production (B6).

---

## E. Google Maps API key (navigation/geo)

| # | Item | Status | Notes |
|---|---|---|---|
| E1 | Car "Navigate" uses the installed Maps app via `ACTION_NAVIGATE` geo intent — **does NOT use the app's Maps key** | ✅ | `CarNavigation.kt`; no key needed for hand-off |
| E2 | Rotate the previously-committed Maps key (still in git history) | 🔲 | Mobile eng (pre-existing item, noted in `api_constants.dart`) |
| E3 | Restrict the Maps key: Application (Android package + release SHA-1) + API (Maps/Places only) | 🔲 | Mobile eng / Cloud admin |

> The Android Auto feature adds **no new** Maps-key surface — E2/E3 are pre-existing
> hygiene items for the phone app's Places/Maps usage, not blockers for Auto.

---

## F. Known limitations / v2 backlog (tracked, not blockers)

| # | Item | Notes |
|---|---|---|
| F1 | Car "Navigate" is **single-destination** | Car geo intent has no waypoints; trip Navigate routes to the first/next stop. Multi-waypoint journeys remain mobile-only. |
| F2 | Signed-out cars see the sign-in gate, not a public station list | Nearby/detail endpoints are called with the bearer token. If a public browse experience is wanted, backend must expose unauthenticated station endpoints; then relax the bridge's `_hasToken` gate for those calls. |
| F3 | In-car map (`MapWithContentTemplate` / NAVIGATION category) | Larger scope + stricter Google review; deferred. |
| F4 | Pre-existing `test/widget_test.dart` stub fails the suite | Not Auto-related; team can delete the stub or add an empty `main()`. |

---

## Go / No-Go summary

- **Code:** ✅ ready — all automated checks green, release AAB builds & signs, R8 keeps car classes.
- **Before production:** run **Phase 10 security sign-off (D1/A4)**, then the **DHU + regression matrix (C1–C5)**, then **Play Console declaration + Google review (B1–B6)**.
- **No backend or phone-app changes required** to ship the current (session-gated) scope.

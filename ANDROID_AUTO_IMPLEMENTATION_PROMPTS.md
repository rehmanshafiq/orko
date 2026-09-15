# Android Auto Implementation Prompt Pack — HUBCO Green (`orko_hubco`)

> **What this document is.** A complete, ordered set of copy‑paste‑ready prompts for a coding agent (Claude Code / Cursor) to implement a production‑ready **Android Auto** experience for the existing `orko_hubco` Flutter app.
>
> **What this document is NOT.** It does not implement Android Auto. It is the engineering prompt pack that drives the implementation phase‑by‑phase.
>
> Every fact below was verified against the actual codebase (commit branch `v1_dev_car_play_auto`). Do **not** invent files, classes, endpoints, or architecture beyond what is stated here. When something is unverified, it is explicitly marked **[VERIFY]**.

---

## 1. PROJECT CONTEXT

| Area | Actual value (verified) |
|---|---|
| App name / purpose | **HUBCO Green** — production EV‑charging app (Pakistan): find charging stations, view details, book slots, live‑charging telemetry, trip planning |
| pubspec name | `orko_hubco` (version `1.0.0+1`) |
| Flutter / Dart | **3.41.9** / **3.11.5** (stable) |
| Android namespace | `com.orko_hubco.mobile.orko_hubco` |
| Android applicationId | `com.orko_hubco.mobile.orko_hubco2` |
| AGP / Gradle / Kotlin | **8.11.1** / **8.14** / **2.2.20** |
| Java / jvmTarget | **17** |
| compileSdk / targetSdk / minSdk | **36 / 36 / 24** (`minSdk = maxOf(flutter.minSdkVersion, 23)`) |
| Build flavors | **None.** Single `debug` + `release` build type. Release = R8 minify + resource shrink + keystore signing (`key.properties`) |
| Architecture | **Clean Architecture** per feature (`data` / `domain` / `presentation`) |
| State management | **flutter_bloc** (Cubit + a few BLoCs) |
| DI | **get_it** (`sl`), one `*_injection.dart` per feature, aggregated in `lib/core/di/injection_container.dart` |
| Navigation | **go_router** (`lib/core/router/app_router.dart`), `StatefulShellRoute.indexedStack` (5 branches), auth‑guarded routes via `AuthNotifier` |
| HTTP | Single **Dio** client `lib/core/network/api_client.dart` → `ApiClient` (get_it lazy singleton). Wrappers `get/post/put/delete/patch`, per‑request content type |
| Base URL | `https://apis-py.orkofleet.com/` (live). Staging fallback `https://staging-python.orkofleet.com/`. Header `Domain: Hubco`. Response envelope `{status, message, body}` |
| Endpoint resolution | **Firebase Remote Config** → `RemoteConfigService.config.apiConstants.apiEndpoints` (~60 paths), with bundled fallback `assets/data/remote_config.json` and per‑datasource hardcoded fallbacks |
| Auth | `Authorization: Bearer <access_token>` injected by `AuthInterceptor`. Token read synchronously from `SecureStore` in‑memory mirror. **No refresh flow** — 401 → `UnauthorizedFailure` → logout |
| Secure storage | `flutter_secure_storage` → Android **EncryptedSharedPreferences** (`aOptions: AndroidOptions(encryptedSharedPreferences: true)`). Keys: `access_token`, `refresh_token` (unused), `user_id`, `cached_user` |
| TLS | Certificate pinning against bundled CA `assets/certs/api_ca_bundle.pem` (`CertificatePinning`). Off in debug; fail‑open if bundle missing |
| Maps | `google_maps_flutter` (manifest key `${MAPS_API_KEY}` from `local.properties`); Google Places via `lib/core/services/google_places_service.dart` |
| Location | `geolocator: ^14.0.2`; permissions `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` |
| Navigation hand‑off | `lib/core/utils/app_functions.dart` → `AppFunctions.openGoogleMapsDirections/openPreferredMapsDirections` via `url_launcher` (`https://www.google.com/maps/dir/?api=1&destination=lat,lng`). Deliberately avoids `google.navigation:` auto‑start |
| Existing platform channels | Exactly **one**: `orko/live_charging_activity` — **iOS‑only** (`ios/Runner/LiveChargingActivityManager.swift`). **Android `MainActivity.kt` is the bare default** (`class MainActivity : FlutterActivity()`), no channel wiring |
| Background execution | No `workmanager`. Two headless Dart entrypoints (`@pragma('vm:entry-point')`): FCM background handler + `flutter_foreground_task` live‑charging isolate |
| **Key reusable precedent** | `lib/core/services/live_charging/live_session_fetcher.dart` → `LiveSessionFetcher` re‑bootstraps the **entire network stack in any isolate** (GetStorage → Firebase → RemoteConfig → SecureStore → CertPinning → `ApiClient`) and reuses real models. **This is the template for the Android Auto data bridge.** |
| Security | Cert pinning; encrypted token store; debug‑only logging (`LoggingInterceptor` gated by `kDebugMode`, never leaks tokens in release); `allowBackup=false` |

### Datasource constructors relevant to Auto (all take `ApiClient` only — trivially reusable)

```dart
// lib/features/map/data/datasources/remote/map_remote_datasource.dart
class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  const MapRemoteDataSourceImpl({required this.apiClient});
  Future<List<HubcoLocationModel>> getNearestStations({
    required double latitude, required double longitude,
    double? radius, List<String>? connectorTypes, List<int>? amenityIds,
    double? minPrice, double? maxPrice, double? powerOutput, String? city });
}

// lib/features/charging/data/datasources/remote/charging_remote_datasource.dart
class ChargingRemoteDataSourceImpl implements ChargingRemoteDataSource {
  const ChargingRemoteDataSourceImpl({required this.apiClient});
  Future<ChargingStationDetailModel> getStationDetail({
    required String stationId, required double latitude, required double longitude });
  Future<ChargerCompatibilityModel> checkChargerCompatibility({
    required int csmsVehicleId, required String chargePointId });
}

// lib/features/booking/data/datasources/remote/booking_remote_datasource_impl.dart
class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  const BookingRemoteDataSourceImpl({required this.apiClient});
  Future<LiveSessionModel> getLiveSession(); // GET remote-config `live_session`
}
```

### Data models the Auto layer will serialize (verified fields)

- **`HubcoLocationEntity`** (nearby): `id(int)`, `name`, `displayName`, `address`, `area`, `city`, `latitude`, `longitude`, `status(bool)`, `distance(double km)`, `iconUrl`, `numberOfConnectors`, `availableConnectors`, `available(bool)`, `connectorTypes(List<String>)`, `powerOutputs(List<double>)`, `prices(List<StationPriceEntity{pricingMode,currency,price}>)`.
- **`ChargingStationDetailEntity`**: `locationId(String)`, `name`, `status(bool)`, `isClosed`, `bannerImage`, `address`, `addressGuide`, `contactNumber`, `openingTime`, `closingTime`, `distance(double)`, `latitude`, `longitude`, `amenities`, `chargers(List<ChargerEntity>)` → each has `connectors(List<ConnectorEntity{connectorType,power,price,connectorState}>)`, `averageRating`, `totalReviews`.
- **`LiveSessionEntity`** (active charging telemetry): `active(bool)`, `sessionId(int)`, `locationName`, `currentChargePercentage`, `chargingSpeedKw`, `energyDeliveredKwh`, `sessionTime`, `timeLeft`, `currentCost`, `totalCost`, `startSoc`, `endSoc`, getters `gaugeProgress`, `priceLabel`.

---

## 2. ANDROID AUTO OBJECTIVE

Android Auto for HUBCO Green is a **separate, driver‑optimized presentation layer** built with the **Android for Cars App Library** (`androidx.car.app`). **It is NOT a rendering of the Flutter mobile UI** — no Flutter widgets are embedded in the car; templates are native Kotlin.

**Users should be able to (while driving):**
1. See **nearby charging stations** (real data from the `nearest` endpoint), ordered by distance, with availability at a glance.
2. Open a **station's details** (address, connector types/power, availability, price, open/closed).
3. **Navigate** to a station (hand off to Google Maps turn‑by‑turn).
4. View **active charging status** (read‑only telemetry: % charged, kW, energy delivered, time left, cost).
5. View their **saved trips** (read‑only) and navigate to a trip's next charging stop.

**Explicitly NOT exposed in Auto (with reasons):**
- **Login / OTP / registration / password reset** — text/credential entry is unsafe and disallowed while driving. Auth happens on the phone; Auto reads the existing session.
- **Booking a slot, payment, QR scan to start charging** — multi‑step, distracting; charging is started by scanning a QR at the charger (`verify-qr`), impossible in Auto.
- **Stop charging** — **no backend endpoint exists** for it, and it is a safety‑sensitive action.
- **Planning / creating / editing / deleting a trip** — requires free‑text origin/destination entry (Google Places) and SoC sliders; **mobile‑only**. In Auto, trips are **read‑only** (view saved trips + navigate to stops).
- **Reviews, favourites management, profile editing, vehicle management** — mobile‑only.

**Relationship to the mobile app:** Auto and the phone share one backend, one auth session (same `access_token` in EncryptedSharedPreferences), one set of endpoints (Remote Config), and one security stack (cert pinning). The car app is a thin native UI over the **same Dart data layer** via a headless `FlutterEngine` bridge.

**Driver safety:** minimal taps, large targets, short strings, no free‑text input, no video/animation, no scrolling‑heavy content, template‑enforced content limits.

---

## 3. ANDROID AUTO FEATURE MATRIX

| Feature | In existing app | In Android Auto | Priority | Classification | Implementation approach |
|---|---|---|---|---|---|
| Authentication (login/OTP) | Yes | **No** (read existing session only) | High | **NOT RECOMMENDED FOR DRIVER USE** | Detect token via bridge `isAuthenticated`; if absent show `MessageTemplate` "Sign in on your phone" |
| Nearby stations | Yes (`nearest`) | **Yes** | High | **MUST HAVE** | `ListTemplate` fed by `MapRemoteDataSourceImpl.getNearestStations` over bridge |
| Station details | Yes (`charging-station/{id}`) | **Yes** | High | **MUST HAVE** | `PaneTemplate` fed by `ChargingRemoteDataSourceImpl.getStationDetail` |
| Charger compatibility | Yes (`charger-compatibility`) | **No** (needs selected vehicle + charge point context) | Low | **MOBILE ONLY** | Not exposed; requires vehicle selection UX unsuitable for driving |
| Navigate to station | Yes (`AppFunctions` → Maps) | **Yes** | High | **MUST HAVE** | Car app fires `ACTION_NAVIGATE` geo intent (native), not `url_launcher` |
| Live charging status | Yes (`live_session`) | **Yes (read‑only)** | High | **MUST HAVE** | `PaneTemplate` fed by `BookingRemoteDataSourceImpl.getLiveSession`, refreshed on a timer |
| Stop charging | **No API** | **No** | — | **NOT RECOMMENDED / NO BACKEND** | Excluded |
| Booking a slot | Yes | **No** | Medium | **MOBILE ONLY** | Multi‑step + payment; unsafe while driving |
| Payment | Yes | **No** | — | **NOT RECOMMENDED FOR DRIVER USE** | Excluded |
| Vehicle management | Yes | **No** | Low | **MOBILE ONLY** | Excluded |
| **View saved trips** | Yes (`saved_trips`, `saved_trip_detail`) | **Yes (read‑only)** | Medium | **SHOULD HAVE** | `ListTemplate` (saved trips) → `PaneTemplate` (stops) via `TripRemoteDataSourceImpl.getSavedTrips` / `getSavedTripDetail` |
| **Navigate to trip stop** | Yes (`AppFunctions.openGoogleMapsJourney`) | **Yes (single stop)** | Medium | **SHOULD HAVE** | Native `ACTION_NAVIGATE` to the selected/next stop's coordinates (geo intent = single destination; multi‑waypoint is mobile‑only) |
| Plan / create / edit / delete trip | Yes (`plan_trip`, `save_trip`, `edit_trip`, `delete_trip`) | **No** | Low | **MOBILE ONLY** | Free‑text origin/destination (Google Places) + SoC sliders; unsafe while driving |
| Search stations | Yes (`search`) | **No** (free‑text) | Low | **NOT RECOMMENDED FOR DRIVER USE** | Free‑text unsafe; nearby list covers discovery |
| Reviews / favourites | Yes | **No** | Low | **MOBILE ONLY** | Excluded |

---

## 4. ANDROID AUTO UX ARCHITECTURE

```
HUBCO Green (CarAppService → Session)
│
├── [entry] Not signed in?  → MessageTemplate "Sign in on your phone"
│
├── Nearby Stations (root, ListTemplate)
│   ├── (row) Station A → Station Details (PaneTemplate)
│   │        ├── [action] Navigate  → Google Maps turn-by-turn (ACTION_NAVIGATE)
│   │        └── [action] Back
│   ├── (row) Station B → …
│   ├── [header action] Refresh (re-query nearest)
│   ├── [header action] Active Charging → Charging Status (PaneTemplate)
│   └── [header action] My Trips → Saved Trips (ListTemplate)
│
├── Active Charging (PaneTemplate, timer-refreshed)
│   ├── % charged · kW · energy delivered · time left · cost
│   ├── (no active session) → MessageTemplate "No active charging session"
│   └── [action] Back
│
└── Saved Trips (ListTemplate, read-only)
    ├── (row) Trip → Trip Detail (PaneTemplate)
    │        ├── stops list: name · SoC in/out · charging mins · connector/power
    │        ├── [action] Navigate to next stop → Google Maps (ACTION_NAVIGATE)
    │        └── [action] Back
    └── (no saved trips) → MessageTemplate "No saved trips"
```

- **Entry / auth flow:** `Session.onCreateScreen` checks `isAuthenticated`. No token → `MessageTemplate` with a single "Refresh" action (re‑checks after the user signs in on the phone). Token present → `NearbyStationsScreen`.
- **Station flow:** location acquired (via bridge) → `getNearestStations` → `ListTemplate` → tap row → `getStationDetail` → `PaneTemplate`.
- **Navigation flow:** `PaneTemplate` "Navigate" `Action` → native `ACTION_NAVIGATE` (`geo:0,0?q=lat,lng(label)`) started from `CarContext`.
- **Charging flow:** `getLiveSession` → if `active` render telemetry pane and schedule a refresh; else `MessageTemplate`.
- **Trip flow:** `getSavedTrips` → `ListTemplate`; tap trip → `getSavedTripDetail(id)` → `PaneTemplate` listing charging stops (name, SoC in/out, charging minutes, connector/power); "Navigate to next stop" → native `ACTION_NAVIGATE` to that stop's coordinates. Read‑only — no create/edit/delete.
- **Error flow:** every bridge call returns a typed result; failures → `MessageTemplate` (see §Phase 8) with a "Retry" action. Never crash.

---

## 5. ANDROID AUTO TEMPLATE MAPPING

> Target library: **`androidx.car.app:app` + `androidx.car.app:app-projected` `1.4.0`** (current stable; supports Auto phone‑projected). **[VERIFY]** the latest stable at implementation time and pin it; do not use alpha/beta.

| Screen | Template | Purpose | Data source (via bridge) |
|---|---|---|---|
| Sign‑in required | `MessageTemplate` | Tell user to sign in on phone; single Refresh action | `isAuthenticated` |
| Nearby stations | `ListTemplate` (rows with title/text + `Metadata`/`Place` for distance) | Browse stations by distance | `getNearbyStations(lat,lng)` → `HubcoLocation` list |
| Station details | `PaneTemplate` (Row items + `Action` buttons) | Show address, connectors, availability, price; Navigate/Back | `getStationDetail(id,lat,lng)` |
| Active charging | `PaneTemplate` (rows for %, kW, energy, time, cost) | Read‑only live telemetry | `getLiveSession()` |
| Saved trips | `ListTemplate` (row per trip) | Browse saved trips | `getSavedTrips()` |
| Trip detail | `PaneTemplate` (row per charging stop + Navigate action) | Show stops + SoC/charging info; navigate to next stop | `getSavedTripDetail(id)` |
| Empty / error | `MessageTemplate` | No stations / no session / no trips / network / auth error | any bridge result error |
| Loading | `ListTemplate`/`PaneTemplate` with `setLoading(true)` | Progress while a bridge call is in flight | — |

**Template choices justified:**
- `ListTemplate` (not `GridTemplate`) — station rows are text‑primary with distance/availability, not image tiles; list is the driver‑standard for POI browsing.
- `PaneTemplate` (not `MapWithContentTemplate`) — the car map is Google Maps’ own during navigation; HUBCO does not hold a `NAVIGATION` template slot, and a detail/telemetry pane is simpler and safer. **[VERIFY]** if a future v2 wants an in‑car map, `MapWithContentTemplate` / `PlaceListNavigationTemplate` require the `androidx.car.app.category.NAVIGATION` category and stricter review.
- `MessageTemplate` for all non‑happy paths — enforces short content and a bounded action set.

**Category:** declare `androidx.car.app.category.CHARGING` (first‑class EV category) — allows POI listing + navigation hand‑off without the full navigation contract.

---

## 6. IMPLEMENTATION PHASES (adapted to this project)

| Phase | Title | Notes for this project |
|---|---|---|
| 0 | Preparation & guardrails | Baseline builds/tests; branch; no behavior change |
| 1 | Auto foundation (Gradle, Manifest, CarAppService, HostValidator, cached FlutterEngine) | New Kotlin `auto/` package; new Dart entrypoint |
| 2 | Data bridge (Dart `androidAutoMain` + `MethodChannel orko/android_auto`) | Reuse `LiveSessionFetcher` bootstrap + real datasources |
| 3 | Authentication gate | Read existing session; `MessageTemplate` when absent |
| 4 | Station discovery (`NearbyStationsScreen`) | `getNearbyStations` + location |
| 5 | Station details (`StationDetailScreen`) | `getStationDetail` |
| 6 | Navigation hand‑off | `ACTION_NAVIGATE` from `CarContext` |
| 7 | Live charging (`ChargingStatusScreen`) | `getLiveSession` + timed refresh |
| 7A | Trip planner — saved trips (read‑only) + stop navigation | `getSavedTrips` / `getSavedTripDetail`; navigate to a stop |
| 8 | Error, empty & offline handling | Typed bridge results → `MessageTemplate` |
| 9 | Lifecycle & FlutterEngine management | Engine create/destroy tied to `Session`/service lifecycle |
| 10 | Security review | Token stays in Dart; HostValidator; ProGuard; no logs |
| 11 | Testing (analyze/test/build + DHU) | Flutter + Gradle + Desktop Head Unit |
| 12 | Production readiness | Play Console Auto declaration, review checklist |

> **Booking (template Phase 7 in the generic brief) is intentionally dropped** — excluded from Auto scope (see §3). **Trip planning is included as read‑only Phase 7A** (view saved trips + navigate to a stop); creating/editing/deleting trips stays mobile‑only. The phase numbering above is the authoritative one for this project.

---

## 7. COPY‑PASTE PROMPTS

> Each prompt is self‑contained. Run them **in order**. Do not let the agent modify Flutter UI, Cubits/BLoCs, repositories, routing, `pubspec.yaml`, or dependency versions unless a prompt explicitly says so.

---

### PHASE 0 — Preparation & Guardrails

```
OBJECTIVE
Establish a known-good baseline before any Android Auto work, on a dedicated branch, changing no runtime behavior.

CONTEXT
- Repo: Flutter app `orko_hubco` (HUBCO Green EV). Flutter 3.41.9 / Dart 3.11.5.
- Android: AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20, Java 17, compileSdk/targetSdk 36, minSdk 24. No flavors.
- Release uses R8 (minify + shrink) with keystore from android/key.properties.
- Maps key comes from android/local.properties as MAPS_API_KEY (see scripts/flutter_maps.sh).

EXISTING FILES (read only)
- android/app/build.gradle.kts, android/app/src/main/AndroidManifest.xml
- android/app/proguard-rules.pro
- android/app/src/main/kotlin/com/orko_hubco/mobile/orko_hubco/MainActivity.kt

FILES TO CREATE
- None (baseline only). Optionally scripts/dhu notes.

FILES TO MODIFY
- None.

IMPLEMENTATION REQUIREMENTS
1. Create branch `feature/android-auto` off the current branch.
2. Run and record results of: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, and `./gradlew :app:assembleDebug` (from android/). Use `scripts/flutter_maps.sh` if builds need MAPS_API_KEY.
3. Do NOT change any code. Only capture the baseline.

CONSTRAINTS
- Do not modify any file. Do not upgrade any dependency. Do not touch pubspec.yaml.

SECURITY REQUIREMENTS
- None (read-only phase).

TESTING REQUIREMENTS
- `flutter analyze` → record PASS/FAIL and warnings count.
- `flutter test` → record PASS/FAIL.
- Debug APK + Gradle assembleDebug → record PASS/FAIL.

ACCEPTANCE CRITERIA
- Baseline results recorded. Branch created. Zero code changes.
```

---

### PHASE 1 — Android Auto Foundation

```
OBJECTIVE
Add the Android for Cars App Library, declare a CarAppService for Android Auto (EV charging category), and stand up a cached background FlutterEngine that the car app will use as its data source. The car must connect and show a placeholder screen.

CONTEXT
- Android namespace: com.orko_hubco.mobile.orko_hubco (NOTE: applicationId is com.orko_hubco.mobile.orko_hubco2, but Kotlin package/namespace is com.orko_hubco.mobile.orko_hubco).
- MainActivity.kt is the bare default (class MainActivity : FlutterActivity()); there is NO existing Android MethodChannel.
- EV charging apps use the first-class category androidx.car.app.category.CHARGING.
- The app already runs a full network stack inside non-main isolates (see lib/core/services/live_charging/live_session_fetcher.dart) — we will reuse that pattern in Phase 2 via a dedicated Dart entrypoint.

EXISTING FILES (reuse / read)
- android/app/build.gradle.kts
- android/app/src/main/AndroidManifest.xml
- android/app/proguard-rules.pro

FILES TO CREATE
- android/app/src/main/kotlin/com/orko_hubco/mobile/orko_hubco/auto/OrkoCarAppService.kt
- android/app/src/main/kotlin/com/orko_hubco/mobile/orko_hubco/auto/OrkoSession.kt
- android/app/src/main/kotlin/com/orko_hubco/mobile/orko_hubco/auto/screens/PlaceholderScreen.kt
- android/app/src/main/res/values/arrays.xml   (host allowlist for release HostValidator)

FILES TO MODIFY
- android/app/build.gradle.kts  → add dependencies:
    implementation("androidx.car.app:app:1.4.0")
    implementation("androidx.car.app:app-projected:1.4.0")
    (add kotlinx-coroutines-android only if not already resolvable)
  [VERIFY the latest STABLE androidx.car.app version and pin it; do not use alpha/beta.]
- android/app/src/main/AndroidManifest.xml → inside <application>:
    <meta-data android:name="androidx.car.app.minCarApiLevel" android:value="1" />
    <service
        android:name=".auto.OrkoCarAppService"
        android:exported="true">
        <intent-filter>
            <action android:name="androidx.car.app.CarAppService" />
            <category android:name="androidx.car.app.category.CHARGING" />
        </intent-filter>
    </service>
- android/app/proguard-rules.pro → add:
    -keep class androidx.car.app.** { *; }
    -dontwarn androidx.car.app.**
    -keep class com.orko_hubco.mobile.orko_hubco.auto.** { *; }

IMPLEMENTATION REQUIREMENTS
1. OrkoCarAppService extends androidx.car.app.CarAppService:
   - createHostValidator(): in debug return HostValidator.ALLOW_ALL_HOSTS_VALIDATOR; in release build a HostValidator that allowlists the known Android Auto hosts (use res/values/arrays.xml `hosts_allowlist`). [VERIFY the current recommended allowlist from Google's car-app samples.]
   - onCreateSession(): return OrkoSession().
2. OrkoSession extends androidx.car.app.Session:
   - onCreateScreen(intent): return PlaceholderScreen(carContext) for now.
3. PlaceholderScreen extends androidx.car.app.Screen and returns a MessageTemplate "HUBCO Green — connected".
4. Do NOT yet create the FlutterEngine bridge (Phase 2). Keep this phase to service discovery + placeholder.

CONSTRAINTS
- Do not modify MainActivity.kt. Do not modify any Dart file. Do not change pubspec.yaml, flavors, signing, or existing manifest entries (permissions, existing service, meta-data).
- Kotlin package MUST be com.orko_hubco.mobile.orko_hubco.auto (matches namespace).

SECURITY REQUIREMENTS
- HostValidator must NOT allow all hosts in release. ALLOW_ALL only under BuildConfig.DEBUG.
- No secrets, tokens, or API keys in Kotlin.

TESTING REQUIREMENTS
- `./gradlew :app:assembleDebug` PASS.
- `flutter build apk --debug` PASS.
- Manual: enable Android Auto Developer mode → "Unknown sources"; connect Desktop Head Unit (DHU); confirm HUBCO Green appears and shows the placeholder MessageTemplate.

ACCEPTANCE CRITERIA
- App builds. Car app is discoverable in DHU and renders the placeholder. No change to phone-app behavior.
```

---

### PHASE 2 — Data Bridge (Dart entrypoint + MethodChannel)

```
OBJECTIVE
Create a headless Dart entrypoint that reuses the app's real network/auth/config stack and exposes read-only data to the car app over a MethodChannel. Wire the Kotlin side to a cached FlutterEngine that runs this entrypoint.

CONTEXT
- PROVEN PATTERN TO COPY: lib/core/services/live_charging/live_session_fetcher.dart (LiveSessionFetcher) already bootstraps GetStorage → Firebase → RemoteConfigService → SecureStore → CertificatePinning → ApiClient inside a non-main isolate, then reuses real models. Mirror this exactly so requests are byte-for-byte identical (auth header, Domain header, cert pinning, endpoints).
- Datasources to reuse (each takes only ApiClient):
    MapRemoteDataSourceImpl(apiClient: ...).getNearestStations(latitude, longitude)
    ChargingRemoteDataSourceImpl(apiClient: ...).getStationDetail(stationId, latitude, longitude)
    BookingRemoteDataSourceImpl(apiClient: ...).getLiveSession()
    TripRemoteDataSourceImpl(apiClient: ...).getSavedTrips() / getSavedTripDetail(id)
- Auth check: SecureStore.instance.read(StorageConstants.accessToken) — non-null/non-empty means a session exists. (There is NO refresh flow; a 401 means "signed out".)
- Location: geolocator ^14.0.2 is available; ACCESS_FINE_LOCATION already granted for the app.
- Existing single channel is orko/live_charging_activity (iOS only). Use a NEW channel name: orko/android_auto.

EXISTING FILES (reuse)
- lib/core/services/live_charging/live_session_fetcher.dart  (bootstrap template)
- lib/core/network/api_client.dart, lib/core/services/secure_store.dart, lib/core/constants/storage_constants.dart
- lib/features/remote_config/data/services/remote_config_service.dart
- lib/features/map/.../map_remote_datasource.dart
- lib/features/charging/.../charging_remote_datasource.dart
- lib/features/booking/.../booking_remote_datasource_impl.dart
- lib/features/trip/data/datasources/remote/trip_remote_datasource_impl.dart
- lib/firebase_options.dart

FILES TO CREATE
- lib/core/services/android_auto/android_auto_bridge.dart
    * top-level `@pragma('vm:entry-point') void androidAutoMain()` that:
      - WidgetsFlutterBinding.ensureInitialized(); DartPluginRegistrant.ensureInitialized();
      - runs the LiveSessionFetcher-style bootstrap ONCE (idempotent), building an ApiClient;
      - registers MethodChannel('orko/android_auto') handler.
    * Methods handled (all return JSON-serializable maps, never throw across the channel):
      - "isAuthenticated" -> { "authenticated": bool }
      - "getNearbyStations" {lat?, lng?} -> { "ok": bool, "error"?: string, "stations": [ {id, name, address, distanceKm, available, availableConnectors, numberOfConnectors, connectorTypes[], powerKw[], priceLabel, lat, lng} ] }
        (if lat/lng missing, resolve via geolocator; on failure return ok:false error:"location")
      - "getStationDetail" {id, lat, lng} -> { "ok", "error"?, "station": {id, name, address, open(bool), distanceKm, connectors:[{type, powerKw, priceLabel, state}], averageRating, contactNumber} }
      - "getLiveSession" -> { "ok", "error"?, "active": bool, "session"?: {locationName, percent, speedKw, energyKwh, timeLeft, cost} }
      - "getSavedTrips" -> { "ok", "error"?, "trips": [ {id, title, originAddress, destinationAddress, totalDistanceKm, totalDriveMinutes, totalChargingMinutes, totalCost, currency, stopCount} ] }
        (title: derive a short label, e.g. "<origin> → <destination>" or fall back to trip id)
      - "getSavedTripDetail" {id} -> { "ok", "error"?, "trip": {id, originAddress, destinationAddress, totalDistanceKm, totalCost, currency,
          stops:[ {sequence, locationName, locationAddress, lat, lng, connectorType, powerKw, arrivalSoc, departureSoc, chargingMinutes, cost} ] } }
    * Map failures to short codes: "auth" (401/no token), "network", "location", "server", "empty".

FILES TO MODIFY
- android/app/src/main/kotlin/.../auto/OrkoSession.kt (or a new bridge class) — see below.

FILES TO CREATE (Kotlin)
- android/app/src/main/kotlin/com/orko_hubco/mobile/orko_hubco/auto/bridge/FlutterAutoBridge.kt
    * Owns a cached FlutterEngine created with a DartExecutor.DartEntrypoint pointing at
      the `androidAutoMain` entrypoint (entrypoint name "androidAutoMain").
      Use FlutterEngine(context) + dartExecutor.executeDartEntrypoint(
        DartEntrypoint(FlutterInjector.instance().flutterLoader().findAppBundlePath(), "androidAutoMain")).
    * Exposes suspend fun call(method, args): JSONObject via a MethodChannel on the engine's binaryMessenger,
      bridging MethodChannel.Result callbacks to a suspendCancellableCoroutine (run channel calls on main thread).
    * Provides typed helpers: suspend fun isAuthenticated(): Boolean, getNearbyStations(...), getStationDetail(...), getLiveSession(), getSavedTrips(), getSavedTripDetail(id).
    * Lifecycle: created lazily; destroyed when the Session/service is destroyed (Phase 9).

IMPLEMENTATION REQUIREMENTS
1. The Dart entrypoint MUST reuse existing datasources/models — do not re-implement HTTP, endpoints, headers, or parsing.
2. The bridge must NEVER send the access token or Authorization header across the channel. Only sanitized display data crosses to Kotlin.
3. All channel handlers must catch everything and return {ok:false, error:<code>} rather than throwing.
4. Register the entrypoint name so it survives AOT/tree-shaking (the @pragma('vm:entry-point') annotation).

CONSTRAINTS
- Do not modify main.dart, existing Cubits/BLoCs, repositories, routing, or pubspec.yaml.
- Do not add new Dart packages (geolocator, dio, etc. already exist).
- Do not change the existing orko/live_charging_activity channel.

SECURITY REQUIREMENTS
- Token stays in Dart/SecureStore; Kotlin never receives it.
- Reuse CertificatePinning (do not disable/weaken). No token/PII logging (respect kDebugMode gating).

TESTING REQUIREMENTS
- Unit-test the Dart handlers where feasible (mock ApiClient or datasources).
- `flutter analyze` PASS. `flutter build apk --debug` PASS. `./gradlew :app:assembleDebug` PASS.
- Manual: from OrkoSession, log the result of a `isAuthenticated` call at startup (debug only) to confirm the engine + channel round-trip works.

ACCEPTANCE CRITERIA
- Cached FlutterEngine boots the androidAutoMain entrypoint; Kotlin can call all six methods (isAuthenticated, getNearbyStations, getStationDetail, getLiveSession, getSavedTrips, getSavedTripDetail) and receive well-formed JSON; no token ever crosses the channel; failures return typed error codes.
```

---

### PHASE 3 — Authentication Gate

```
OBJECTIVE
Gate the car experience on the existing phone session. If not signed in, show a MessageTemplate telling the user to sign in on their phone, with a Refresh action.

CONTEXT
- No login in the car (unsafe). Session presence = SecureStore access_token exists (bridge "isAuthenticated").
- No refresh flow exists; treat a later "auth" error from any call as signed-out and route back to this screen.

EXISTING FILES (reuse)
- auto/OrkoSession.kt, auto/bridge/FlutterAutoBridge.kt (Phase 2)

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/screens/SignInRequiredScreen.kt

FILES TO MODIFY
- auto/OrkoSession.kt → onCreateScreen: call bridge.isAuthenticated(); if false return SignInRequiredScreen, else NearbyStationsScreen (Phase 4). Until Phase 4 lands, keep PlaceholderScreen as the authed target.

IMPLEMENTATION REQUIREMENTS
1. SignInRequiredScreen: MessageTemplate with title "Sign in required", message "Open HUBCO Green on your phone to sign in.", one Action "Refresh" that re-checks isAuthenticated and invalidates()/pushes forward when true.
2. Any screen receiving an "auth" error code from the bridge must screenManager.push(SignInRequiredScreen) (or pop to it).

CONSTRAINTS
- No credential entry, no OTP, no text input in the car. Do not modify Flutter auth code.

SECURITY REQUIREMENTS
- Do not display any token, phone number, email, or user id in the car.

TESTING REQUIREMENTS
- DHU: signed-out state shows SignInRequiredScreen; after signing in on phone, Refresh advances to the station list.
- `flutter analyze` / builds PASS.

ACCEPTANCE CRITERIA
- Correct branch on session presence; graceful handling when the session is missing or expires mid-use.
```

---

### PHASE 4 — Station Discovery (Nearby Stations)

```
OBJECTIVE
Show a driver-safe list of nearby charging stations using live data.

CONTEXT
- Source: bridge.getNearbyStations(lat?,lng?) → MapRemoteDataSourceImpl.getNearestStations (endpoint remote-config `charging_station_map` → api/v1/charging-station/nearest?; returns HubcoLocation fields incl. distance(km), available, availableConnectors/numberOfConnectors, connectorTypes, powerOutputs, prices).
- Location: bridge resolves via geolocator if lat/lng not supplied.

EXISTING FILES (reuse)
- auto/bridge/FlutterAutoBridge.kt, lib/features/map/... (already reused by the bridge)

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/screens/NearbyStationsScreen.kt
- android/app/src/main/kotlin/.../auto/model/AutoStation.kt (parse channel JSON → data class)

FILES TO MODIFY
- auto/OrkoSession.kt → authed target = NearbyStationsScreen.

IMPLEMENTATION REQUIREMENTS
1. ListTemplate with setHeaderAction(Action.APP_ICON), title "Nearby stations".
2. On load: setLoading(true); launch a coroutine; call bridge.getNearbyStations(); on result build rows.
3. Each Row: title = station name; text line = "<distance> km · <available>/<total> · <connectorTypes joined>"; onClick → push StationDetailScreen(id, lat, lng). Consider a Place/marker with distance metadata if using PlaceListMapTemplate is NOT chosen (stick to ListTemplate for CHARGING category simplicity).
4. Cap rows to the template's max (ListTemplate item limit ~6 per section on many head units) — show the nearest N; do not paginate heavily.
5. Header actions: "Refresh" (re-query) and "Charging" (push ChargingStatusScreen — Phase 7).
6. Errors: "empty" → MessageTemplate "No stations nearby"; "location" → MessageTemplate "Location unavailable" + Retry; "auth" → SignInRequiredScreen; "network"/"server" → MessageTemplate + Retry.

CONSTRAINTS
- Do not modify MapCubit / map feature Dart code. Reuse the datasource only via the bridge.
- Keep strings short; no images beyond optional station icon; no scrolling-heavy content.

SECURITY REQUIREMENTS
- Display only public station info. No user PII.

TESTING REQUIREMENTS
- DHU: list renders with real staging/live data; distances plausible; tap → detail.
- Error paths verified by simulating no-network and denied-location.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Real nearby stations render, ordered by distance, tappable, with correct availability; all error states handled without crashing.
```

---

### PHASE 5 — Station Details

```
OBJECTIVE
Show a station's key details in a driver-safe pane with a Navigate action.

CONTEXT
- Source: bridge.getStationDetail(id, lat, lng) → ChargingRemoteDataSourceImpl.getStationDetail (endpoint remote-config `charging_station_detail` → api/v1/charging-station/{id}). Fields: name, address/addressGuide, status/open, distance, connectors[{connectorType, power, price, connectorState}], averageRating, contactNumber, openingTime/closingTime.

EXISTING FILES (reuse)
- auto/bridge/FlutterAutoBridge.kt, auto/model/AutoStation.kt

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/screens/StationDetailScreen.kt
- (extend model) AutoStationDetail data class in auto/model/

FILES TO MODIFY
- NearbyStationsScreen.kt → push StationDetailScreen on row click.

IMPLEMENTATION REQUIREMENTS
1. PaneTemplate: setHeaderAction(Action.BACK); title = station name.
2. Rows: address; open/closed + hours; connectors summary ("DC 60 kW · Available"); price label; rating (optional).
3. Actions: primary "Navigate" (Phase 6 wires the intent); keep to <=2 actions.
4. On load setLoading(true); coroutine; handle the same error codes as Phase 4.

CONSTRAINTS
- Do not modify the charging feature Dart code. Reuse via bridge only.

SECURITY REQUIREMENTS
- Public station info only.

TESTING REQUIREMENTS
- DHU: detail renders for multiple stations; Navigate button present.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Correct, real details render; Back returns to the list; Navigate is present (functional after Phase 6).
```

---

### PHASE 6 — Navigation Hand‑off

```
OBJECTIVE
Start turn-by-turn navigation to a station from the car, using the car's navigation app (Google Maps), not the phone's url_launcher.

CONTEXT
- Phone app uses AppFunctions.openGoogleMapsDirections (url_launcher) — NOT usable from a CarAppService. In the car, start navigation via a geo/ACTION_NAVIGATE intent through CarContext.
- HUBCO uses the CHARGING category (not NAVIGATION), so we HAND OFF to Google Maps rather than drawing our own nav.

EXISTING FILES (reuse)
- StationDetailScreen.kt, AutoStationDetail (lat/lng)

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/util/CarNavigation.kt (helper to build + start the intent)

FILES TO MODIFY
- StationDetailScreen.kt → "Navigate" Action calls CarNavigation.navigateTo(carContext, lat, lng, label).

IMPLEMENTATION REQUIREMENTS
1. Build Intent(CarContext.ACTION_NAVIGATE, Uri.parse("geo:0,0?q=<lat>,<lng>(<label>)")).
2. Start via carContext.startCarApp(intent). Wrap in try/catch; on failure show a CarToast or MessageTemplate "No navigation app available".
3. URL-encode the label; never inject unescaped user/station text.

CONSTRAINTS
- Do not use url_launcher or the phone MainActivity. Do not modify AppFunctions.
- Do not auto-start navigation without an explicit user tap.

SECURITY REQUIREMENTS
- Only pass coordinates + a short public label. No PII.

TESTING REQUIREMENTS
- DHU with Google Maps: Navigate launches Maps routing to the station.
- Failure path (no maps) handled gracefully.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Tapping Navigate reliably starts navigation to the correct coordinates; graceful fallback when unavailable.
```

---

### PHASE 7 — Live Charging Status (read‑only)

```
OBJECTIVE
Show read-only live charging telemetry with periodic refresh; handle "no active session".

CONTEXT
- Source: bridge.getLiveSession() → BookingRemoteDataSourceImpl.getLiveSession() (remote-config `live_session`). LiveSessionEntity fields: active, locationName, currentChargePercentage, chargingSpeedKw, energyDeliveredKwh, timeLeft, currentCost/totalCost, gaugeProgress, priceLabel.
- The phone already polls this (charging_status_cubit ~10s; live-charging foreground isolate ~5s). In the car, poll on a modest interval only while this screen is visible.
- STOP CHARGING IS OUT OF SCOPE (no backend endpoint; safety). Do NOT add any stop/start controls.

EXISTING FILES (reuse)
- auto/bridge/FlutterAutoBridge.kt, lib/features/booking/... (via bridge)

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/screens/ChargingStatusScreen.kt
- android/app/src/main/kotlin/.../auto/model/AutoLiveSession.kt

FILES TO MODIFY
- NearbyStationsScreen.kt → "Charging" header action pushes ChargingStatusScreen.

IMPLEMENTATION REQUIREMENTS
1. On visible (Lifecycle START): start a coroutine timer (e.g. every 15–20s) calling getLiveSession(); on STOP cancel it.
2. active=true → PaneTemplate rows: "<percent>%", "<speedKw> kW", "<energyKwh> kWh", "Time left: <timeLeft>", "Cost: <cost>", header = locationName. Use invalidate() to refresh.
3. active=false or "empty" → MessageTemplate "No active charging session" + Back.
4. Error codes handled as in Phase 4 (auth → SignInRequiredScreen).
5. Read-only: no start/stop actions.

CONSTRAINTS
- Do not modify charging_status_cubit or live_charging services. Reuse via bridge only.
- Do not run the timer while the screen is not resumed (battery/data).

SECURITY REQUIREMENTS
- Telemetry only; no payment details or PII beyond station/session display fields.

TESTING REQUIREMENTS
- DHU with an active session (staging): values update on refresh.
- No-session state renders the message.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Live telemetry displays and refreshes only while visible; no-session and error states handled; no stop/start controls exist.
```

---

### PHASE 7A — Trip Planner (Saved Trips, read‑only + Stop Navigation)

```
OBJECTIVE
Let the driver browse their SAVED trips and navigate to a trip's charging stop. Read-only: no planning, creating, editing, or deleting in the car.

CONTEXT
- Source (reuse via the Phase 2 bridge, do NOT re-implement HTTP):
    TripRemoteDataSourceImpl(apiClient: ...).getSavedTrips()      -> List<SavedTripModel>  (remote-config `saved_trips` → api/v1/trip-planning/trips/)
    TripRemoteDataSourceImpl(apiClient: ...).getSavedTripDetail(id)-> SavedTripModel        (remote-config `saved_trip_detail` → api/v1/trip-planning/trips/{id}/)
  Constructor is `const TripRemoteDataSourceImpl({required this.apiClient})` — same trivial reuse as the other datasources.
- SavedTripEntity fields: id, vehicle?, originLatitude/Longitude, originAddress?, destinationLatitude/Longitude, destinationAddress?, startSoc,
  totalDistanceKm, totalDriveMinutes, totalChargingMinutes, totalCost, currency, status, createdAt, stops: List<TripStopEntity>.
- TripStopEntity fields: sequence, locationId, locationName, locationAddress?, latitude, longitude, connectorId?, connectorType,
  connectorTypeMatchesVehicle, connectorPowerKw, arrivalSoc, departureSoc, energyAddedKwh, chargingMinutes, cost, amenities.
- IMPORTANT LIMITATION: the phone app does multi-stop routing via AppFunctions.openGoogleMapsJourney (path-based https Maps URL, url_launcher).
  The car's native CarContext.ACTION_NAVIGATE (geo: intent) supports a SINGLE destination only — no waypoints. So in the car, "Navigate"
  routes to ONE selected stop (the next/first stop by default). Multi-waypoint journeys remain mobile-only.
- PLANNING/CREATING trips requires free-text origin/destination (Google Places) + SoC sliders → EXCLUDED from Auto (unsafe while driving).

EXISTING FILES (reuse)
- auto/bridge/FlutterAutoBridge.kt (Phase 2, now exposing getSavedTrips / getSavedTripDetail)
- auto/util/CarNavigation.kt (Phase 6 navigation helper)
- lib/features/trip/... (reused ONLY via the bridge; no Dart changes)

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/screens/SavedTripsScreen.kt       (ListTemplate)
- android/app/src/main/kotlin/.../auto/screens/TripDetailScreen.kt       (PaneTemplate)
- android/app/src/main/kotlin/.../auto/model/AutoTrip.kt                  (AutoTrip + AutoTripStop data classes parsed from channel JSON)

FILES TO MODIFY
- NearbyStationsScreen.kt → add a header Action "My Trips" that pushes SavedTripsScreen.

IMPLEMENTATION REQUIREMENTS
1. SavedTripsScreen:
   - ListTemplate, setHeaderAction(Action.BACK), title "My trips".
   - On load setLoading(true); coroutine → bridge.getSavedTrips().
   - Each Row: title = trip title ("<origin> → <destination>" or a short fallback); text = "<totalDistanceKm> km · <stopCount> stops · <totalCost> <currency>".
   - onClick → push TripDetailScreen(tripId).
   - Cap rows to the template item limit; show most recent first if order matters.
2. TripDetailScreen:
   - PaneTemplate, setHeaderAction(Action.BACK), title = trip title.
   - On load setLoading(true); coroutine → bridge.getSavedTripDetail(id).
   - Rows: a summary row (distance · drive time · charging time · cost), then one Row per charging stop:
       title = "<sequence>. <locationName>"
       text  = "SoC <arrivalSoc>%→<departureSoc>% · <chargingMinutes> min · <connectorType> <connectorPowerKw> kW"
   - Primary Action "Navigate to next stop": CarNavigation.navigateTo(carContext, stop.lat, stop.lng, stop.locationName) for the first stop
     (or a stop the user selected). Keep to <=2 actions.
3. Error handling (reuse Phase 8 helpers): "empty" → MessageTemplate "No saved trips" / "This trip has no stops";
   "auth" → SignInRequiredScreen; "network"/"server" → MessageTemplate + Retry.
4. Read-only: NO create/edit/delete/save actions anywhere in these screens.

CONSTRAINTS
- Do not modify the trip feature Dart code (trip_planner_bloc, datasource, models) or pubspec.yaml. Reuse via the bridge only.
- Do not use url_launcher / AppFunctions from the car. Navigation goes through CarNavigation (Phase 6).
- Keep strings short; no maps rendering; no free-text input.

SECURITY REQUIREMENTS
- Display only trip/stop info needed for the driver. Do not surface vehicle registration, user id, or any PII beyond addresses already shown on the phone.
- Token stays in Dart (never crosses the channel).

TESTING REQUIREMENTS
- DHU with an account that has saved trips (staging): trips list renders; tap → stops render with SoC/charging info; Navigate routes to the first stop in Google Maps.
- Empty account → "No saved trips". Error paths (no network, signed out) handled.
- `flutter analyze` / `flutter build apk --debug` / `./gradlew :app:assembleDebug` PASS.

ACCEPTANCE CRITERIA
- Real saved trips and their stops render read-only; Navigate reliably routes to the correct stop coordinates; no create/edit/delete controls; all error/empty states handled without crashing.
```

---

### PHASE 8 — Error, Empty & Offline Handling

```
OBJECTIVE
Ensure every screen fails gracefully with a consistent, driver-safe error UX and never crashes.

CONTEXT
- Bridge returns typed codes: "auth", "network", "location", "server", "empty". Backend has no token refresh (auth error = signed out).

FILES TO CREATE
- android/app/src/main/kotlin/.../auto/util/ErrorScreens.kt (helpers building MessageTemplate for each code with an optional Retry action)

FILES TO MODIFY
- NearbyStationsScreen, StationDetailScreen, ChargingStatusScreen, SavedTripsScreen, TripDetailScreen, SignInRequiredScreen → route all failures through ErrorScreens.

IMPLEMENTATION REQUIREMENTS
1. Map codes → messages: auth→SignInRequiredScreen; network→"No internet connection"; location→"Location unavailable"; server→"Something went wrong"; empty→context-specific ("No stations nearby" / "No active charging session").
2. Provide a single Retry action that re-invokes the originating call.
3. Guard against null/partial JSON from the bridge (defensive parsing).

CONSTRAINTS
- No stack traces or raw error strings shown in the car. No Dart-side changes.

SECURITY REQUIREMENTS
- Error messages must not leak tokens, URLs with params, or PII.

TESTING REQUIREMENTS
- Simulate: airplane mode (network), denied location, signed-out (auth), empty results.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Every failure yields a clean MessageTemplate with correct copy and working Retry; no crashes; no leaked internals.
```

---

### PHASE 9 — Lifecycle & Background / FlutterEngine Management

```
OBJECTIVE
Manage the cached FlutterEngine and any timers correctly across the CarAppService/Session lifecycle to avoid leaks and wasted resources.

CONTEXT
- The car app runs in the same process as the phone app but independently of MainActivity's FlutterEngine.
- The bridge engine (Phase 2) must be created lazily and destroyed with the Session/service.

FILES TO MODIFY
- auto/OrkoCarAppService.kt, auto/OrkoSession.kt, auto/bridge/FlutterAutoBridge.kt
- ChargingStatusScreen.kt (timer tied to Lifecycle)

IMPLEMENTATION REQUIREMENTS
1. Create the bridge engine on first use; hold it at Session scope.
2. On Session/ Service onDestroy: cancel coroutines, tear down MethodChannel, call flutterEngine.destroy(). Ensure idempotency.
3. Screen timers use the Screen's Lifecycle (DefaultLifecycleObserver) — start on onResume/START, cancel on onStop/onPause.
4. Do NOT interfere with the phone app's engine, FCM handler, or the live-charging foreground service.

CONSTRAINTS
- No changes to main.dart or existing background services.

SECURITY REQUIREMENTS
- Ensure no lingering engine holds decrypted token state after teardown (SecureStore mirror lives in the engine isolate; destroying the engine clears it).

TESTING REQUIREMENTS
- DHU: connect/disconnect repeatedly; verify no leak/crash; verify phone app + live-charging notification still work concurrently.
- Builds + analyze PASS.

ACCEPTANCE CRITERIA
- Engine and timers are created/destroyed cleanly with lifecycle; no leaks; phone functionality unaffected.
```

---

### PHASE 10 — Security Review

```
OBJECTIVE
Verify the Android Auto implementation preserves the app's existing security posture.

CONTEXT
- Existing posture: Bearer token in EncryptedSharedPreferences; cert pinning (release); debug-only logging; allowBackup=false.

FILES TO REVIEW
- All auto/*.kt, lib/core/services/android_auto/android_auto_bridge.dart, manifest + proguard changes.

IMPLEMENTATION REQUIREMENTS (review checklist — fix any violation)
1. Token/Authorization header NEVER crosses the MethodChannel or appears in Kotlin.
2. No token/PII in logs (Kotlin Log.* and Dart AppLogger must be silent on secrets; AppLogger.d already debug-gated — keep it that way).
3. CertificatePinning reused unchanged (not disabled) for all Auto network calls.
4. HostValidator is NOT ALLOW_ALL in release.
5. CarAppService is exported (required) but exposes only the intended templates; no arbitrary intents honored.
6. Navigation intent passes only coordinates + escaped label.
7. No new secrets/keys added to Kotlin, manifest, or resources.
8. No weakening of TLS/SSL, no new cleartext traffic, no android:usesCleartextTraffic.

CONSTRAINTS
- Do not weaken any existing mechanism to make Auto "work".

TESTING REQUIREMENTS
- Run: security-review (or manual grep) for `Authorization`, `Bearer`, `access_token`, `Log.`, `print(` in auto/ and the bridge.
- Confirm release build still pins certs (build a release APK/AAB with the real CA bundle).

ACCEPTANCE CRITERIA
- All checklist items pass; documented evidence for each.
```

---

### PHASE 11 — Testing

```
OBJECTIVE
Validate the full Auto experience and confirm zero regression to the phone app.

TESTING REQUIREMENTS
1. Flutter: `flutter analyze` (PASS, no new warnings), `flutter test` (PASS).
2. Build: `flutter build apk --debug` and `./gradlew :app:assembleDebug` (PASS); then a `--release` AAB with MAPS_API_KEY + keystore to confirm R8/proguard keeps car classes.
3. Desktop Head Unit (DHU) matrix:
   - Service discovery (app appears in Auto).
   - Signed-out → SignInRequiredScreen; sign in on phone → Refresh advances.
   - Nearby stations render with real data; ordered by distance.
   - Station detail renders; Navigate launches Google Maps.
   - Active charging telemetry renders + refreshes; no-session message.
   - Saved trips list renders; trip detail shows stops; Navigate routes to a stop; no-trips message.
   - Error states: no network, denied location, server error, empty.
   - Back navigation across all screens.
   - Lifecycle: connect/disconnect repeatedly; concurrent phone use + live-charging notification.
4. Regression: phone app startup, login, map, notifications, FCM, live-charging foreground service, release build — all unchanged.

CONSTRAINTS
- Do NOT claim any result that was not actually executed. Record PASS/FAIL/NOT AVAILABLE per item (DHU/vehicle steps are manual).

ACCEPTANCE CRITERIA
- Documented results for every item; all automated checks PASS; DHU flows verified or explicitly marked pending.
```

---

### PHASE 12 — Production Readiness

```
OBJECTIVE
Prepare for Play Store distribution of the Android Auto feature.

IMPLEMENTATION REQUIREMENTS (mostly non-code / release ops)
1. Play Console: declare Android Auto support and the CHARGING category; complete the Cars app quality questionnaire; submit for Google's Android Auto review.
2. Confirm the app's Auto category and templates comply with the current Driver Distraction / Car App Quality guidelines. [VERIFY against current Google docs.]
3. Ensure release signing + R8 keep-rules verified (Phase 10/11) so car classes aren't stripped.
4. Rotate/scope the Google Maps API key (Application + API restrictions) if navigation/geo relies on it. [Note: geo intent hand-off uses the installed Maps app, not the app's key.]
5. Document remaining manual/external steps.

REMAINING WORK / OUT-OF-ENVIRONMENT (call out explicitly)
- Desktop Head Unit and real-vehicle testing.
- Play Console configuration + Google Android Auto review/approval.
- Any backend changes if a public (unauthenticated) station list is desired for signed-out cars (currently gated on session).
- Optional v2: multi-waypoint trip navigation (car geo intent is single-destination today, so v1 routes to one stop); in-car map (NAVIGATION category) — larger review scope.

ACCEPTANCE CRITERIA
- A written go-live checklist with owners; all code-side items green; external items tracked.
```

---

## 8. GLOBAL CONSTRAINTS (apply to EVERY prompt)

- **Do not** modify: `main.dart`, Flutter UI, Cubits/BLoCs, repositories, `go_router` config, `pubspec.yaml`, dependency versions, flavors (none exist), signing, or the existing `orko/live_charging_activity` channel.
- **Reuse, don't duplicate:** all backend access goes through the existing Dart datasources/`ApiClient` via the bridge. No native HTTP, no hardcoded endpoints, no re-implemented auth or cert pinning.
- **Security:** the access token never leaves Dart; no secret logging; HostValidator restricted in release; TLS pinning preserved.
- **Driver safety:** native Car App templates only; short strings; minimal taps; no free‑text input; no start/stop charging; no booking/payment.
- **Honesty:** never claim a build/test/DHU result that wasn't actually run; mark DHU/vehicle/Play Console steps as manual.
- **Kotlin package** for all car code: `com.orko_hubco.mobile.orko_hubco.auto` (matches the Android `namespace`, which differs from the `applicationId` suffix `...orko_hubco2`).

## 9. THINGS TO VERIFY AT IMPLEMENTATION TIME (marked [VERIFY] above)
- Latest **stable** `androidx.car.app` / `app-projected` version (pin exact; no alpha/beta).
- Current recommended **HostValidator allowlist** from Google's car‑app samples.
- Current **Car App Quality / Driver Distraction** guidelines for the CHARGING category and template limits (e.g., `ListTemplate` row caps).
- Whether the `nearest` / `station detail` endpoints work **without** a bearer token (would allow a signed‑out browse experience) — currently the design gates on session.
```

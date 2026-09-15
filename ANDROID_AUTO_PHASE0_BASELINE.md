# Android Auto — Phase 0 Baseline (known-good, pre-implementation)

**Branch:** `feature/android-auto` (created off `v1_dev_car_play_auto`)
**Date captured:** 2026-09-14
**Code changes in this phase:** none (baseline only)

## Environment (verified)
| Item | Value |
|---|---|
| Flutter / Dart | 3.41.9 / 3.11.5 (stable) |
| AGP / Gradle / Kotlin / Java | 8.11.1 / 8.14 / 2.2.20 / 17 |
| compileSdk / targetSdk / minSdk | 36 / 36 / 24 |
| Flavors | none |
| Maps key | `android/local.properties` → `MAPS_API_KEY` (present); injected via `scripts/flutter_maps.sh` |

## Baseline results

| Check | Result | Detail |
|---|---|---|
| `flutter pub get` | **PASS** | Resolved. 131 packages have newer (constraint-incompatible) versions — informational only. |
| `flutter analyze` | **PASS (0 errors)** | 30 issues total: **0 errors, 20 warnings, 10 info** — all pre-existing. Full list saved during the run. |
| `flutter test` | **FAIL (pre-existing, not a logic failure)** | 9/9 real tests in `test/live_session_booking_test.dart` **PASS**. The suite reports failure only because `test/widget_test.dart` is an intentionally-empty stub (2 comment lines, no `main`) — unchanged since project-init commit `da252be5`. |
| `flutter build apk --debug` | **PASS** | `build/app/outputs/flutter-apk/app-debug.apk` (~203 MB debug), exit 0, Gradle task ~1203s (cold, first-time deps download). |
| `./gradlew :app:assembleDebug` | **PASS** | BUILD SUCCESSFUL in 49s (warm cache). |

## Pre-existing observations (NOT introduced by Auto work; do not fix in Phase 0)
1. **`flutter test` non-green** — caused solely by the `main`-less `test/widget_test.dart` stub. Team may later delete the stub or add an empty `main()`; out of Phase 0 scope (zero code changes).
2. **20 analyzer warnings / 10 info** — unused imports/fields, deprecated `withOpacity`/`setMapStyle`/color getters, one duplicate import in `booking_remote_datasource_impl.dart`. Pre-existing.
3. **Gradle deprecations** — build warns it is "incompatible with Gradle 9.0". Pre-existing; unrelated to Auto.

## Acceptance criteria — met
- [x] Branch `feature/android-auto` created.
- [x] Baseline results recorded (this file).
- [x] Zero code changes (only this baseline note + the untracked prompt-pack docs were added).

## Regression gate for later phases
After each Android Auto phase, re-run the five checks. The bar to hold:
- `flutter analyze`: **0 errors**, and **no new** warnings/info beyond the 30 baseline (Auto code should add none).
- `flutter test`: the 9 real tests still **PASS** (the `widget_test.dart` stub failure remains the only failure until the team addresses it separately).
- `flutter build apk --debug` and `./gradlew :app:assembleDebug`: **PASS**.

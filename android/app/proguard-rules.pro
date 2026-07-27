# ProGuard / R8 rules for release builds (minify + resource shrink enabled in
# app/build.gradle.kts). Keep rules below prevent R8 from stripping classes that
# are only reached via reflection / JNI / platform channels.

# ── Flutter engine ──────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ── Google Play Core (referenced by Flutter's deferred-components support) ────
# Prevents "Missing class com.google.android.play.core.*" R8 errors.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ── Firebase (core / messaging / analytics / remote config) ──────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── flutter_local_notifications (uses Gson + scheduled receivers) ────────────
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class * { @com.google.gson.annotations.SerializedName <fields>; }
# Keep generic signatures so Gson TypeToken reflection keeps working.
-keepattributes Signature
-keepattributes *Annotation*

# ── Keep annotations used for JSON / keep enums intact ───────────────────────
-keepclassmembers enum * { *; }

# ── Suppress notes for optional desugar / kotlin metadata ────────────────────
-dontwarn kotlin.**
-dontwarn org.jetbrains.annotations.**

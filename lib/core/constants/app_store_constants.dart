/// Fallback store listings for the soft/force update prompts.
///
/// The primary links come from Remote Config (`play_store_url` /
/// `app_store_url`); these are used when it doesn't provide them (e.g. an
/// older Firebase value) or they fail to open. Keep them in sync with the
/// published listings.
class AppStoreConstants {
  AppStoreConstants._();

  /// Android `applicationId` (see `android/app/build.gradle.kts`).
  static const String androidPackageName = 'com.orko_hubco.mobile.orko_hubco2';

  /// App Store id of "Hubco Green Limited - HGL" (bundle id
  /// `com.orkohubco.mobile.orkoHubco`), as returned by
  /// https://itunes.apple.com/lookup?bundleId=com.orkohubco.mobile.orkoHubco.
  /// Update it only if the app is ever moved to a new App Store record.
  static const String iosAppStoreId = '6785873046';

  /// Opens the Play Store app directly.
  static final Uri playStoreAppUri =
      Uri.parse('market://details?id=$androidPackageName');

  /// Browser fallback when the Play Store app isn't available.
  static final Uri playStoreWebUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$androidPackageName',
  );

  /// Opens the App Store app directly.
  static final Uri appStoreAppUri =
      Uri.parse('itms-apps://apps.apple.com/app/id$iosAppStoreId');

  /// Browser fallback (iOS hands it to the App Store anyway).
  static final Uri appStoreWebUri = Uri.parse(
    'https://apps.apple.com/us/app/hubco-green-limited-hgl/id$iosAppStoreId',
  );
}

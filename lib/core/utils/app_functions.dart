/* This file is only to write down global functions in the application */
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cache/local_cache.dart';


class AppFunctions {
  static Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  /// Opens Google Maps showing the route (line) from the user's current
  /// location to the station, WITHOUT auto-starting turn-by-turn navigation.
  ///
  /// The universal `maps/dir/?api=1` URL opens the Google Maps app when it is
  /// installed and only previews the directions. The `google.navigation:`
  /// scheme (Android) and `directionsmode` deep link (iOS) are intentionally
  /// avoided — both launch navigation immediately, which is not wanted here.
  static Future<void> openGoogleMapsDirections({
    required double latitude,
    required double longitude,
  }) async {
    final destination = '$latitude,$longitude';

    final directionsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$destination&travelmode=driving',
    );

    if (!await launchUrl(directionsUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  static void closeKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static Future<String> getVersionName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static String? getRemoteConfigText(String text) {
    return LocalCache.currentLocalizeContent?[text];
  }

}
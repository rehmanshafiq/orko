/* This file is only to write down global functions in the application */
import 'dart:io';

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

  /// Opens the user's preferred maps application in directions mode: from the
  /// device's current location to the given point.
  ///
  /// The origin is intentionally omitted from every URL so the maps app uses
  /// the user's live location as the starting point. iOS: opens Google Maps
  /// directions when installed, otherwise Apple Maps directions. Android (and
  /// any failure above) falls back to the universal Google Maps directions
  /// URL, which opens the Google Maps app when installed.
  static Future<void> openPreferredMapsDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final point = '$latitude,$longitude';

    if (Platform.isIOS) {
      if (await _tryLaunch(
        Uri.parse('comgooglemaps://?daddr=$point&directionsmode=driving'),
      )) {
        return;
      }
      if (await _tryLaunch(
        Uri.parse('https://maps.apple.com/?daddr=$point&dirflg=d'),
      )) {
        return;
      }
    }

    await openGoogleMapsDirections(latitude: latitude, longitude: longitude);
  }

  /// Attempts to launch [uri] in an external app; false when nothing handles it.
  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens Google Maps with a full journey as ONE route: origin → each
  /// charging stop (in sequence) → destination.
  ///
  /// Uses the path-based `maps/dir/<point>/<point>/...` URL: unlike the
  /// `api=1&waypoints=` form (which renders waypoints as small dots), every
  /// point here is an explicit route stop, so each charging stop gets its own
  /// marker on the mapped route and the user taps Start to begin navigation.
  static Future<void> openGoogleMapsJourney({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    List<({double latitude, double longitude})> stops = const [],
  }) async {
    // The Google Maps app supports at most 9 intermediate stops per route;
    // extras are dropped from the end (stop order is preserved).
    final points = <String>[
      '$originLatitude,$originLongitude',
      ...stops.take(9).map((s) => '${s.latitude},${s.longitude}'),
      '$destinationLatitude,$destinationLongitude',
    ].join('/');

    final journeyUri = Uri.parse('https://www.google.com/maps/dir/$points');

    if (!await launchUrl(journeyUri, mode: LaunchMode.externalApplication)) {
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
/* This file is only to write down global functions in the application */
import 'dart:collection';
import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Opens turn-by-turn directions in the Google Maps app when available.
  static Future<void> openGoogleMapsDirections({
    required double latitude,
    required double longitude,
  }) async {
    final destination = '$latitude,$longitude';

    if (!kIsWeb && Platform.isAndroid) {
      final navigationUri = Uri.parse('google.navigation:q=$destination');
      if (await canLaunchUrl(navigationUri)) {
        await launchUrl(navigationUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!kIsWeb && Platform.isIOS) {
      final mapsUri = Uri.parse(
        'comgooglemaps://?daddr=$destination&directionsmode=driving',
      );
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination',
    );

    if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
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
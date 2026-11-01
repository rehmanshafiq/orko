import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_integrity/app_integrity.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:orko_hubco/core/network/interceptors/error_interceptor.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Produces the app-integrity headers the Hubco backend checks on every API
/// call (see `IntegrityInterceptor`):
/// * Android — a fresh Play Integrity token in [integrityTokenHeader];
/// * iOS — an App Attest assertion over `"<METHOD> <path>"` in
///   [attestKeyIdHeader] / [attestAssertionHeader], after a one-time key
///   attestation with the backend.
///
/// One instance per isolate. Native state (Play provider, App Attest key) is
/// process-wide, so the phone, car and background isolates share it.
///
/// Never throws and never blocks a request indefinitely: when a proof can't be
/// produced the request goes out without it, and the backend decides (logs it
/// in monitor mode, answers 403 in enforce mode — handled by the interceptor).
class AppIntegrityService {
  AppIntegrityService._();

  static final AppIntegrityService instance = AppIntegrityService._();

  /// Number of the hubco Google Cloud project the app is linked to in Play
  /// Console (`project_number` in google-services.json).
  static const int cloudProjectNumber = 60291270702;

  static const String integrityTokenHeader = 'X-Integrity-Token';
  static const String attestKeyIdHeader = 'X-App-Attest-Key-Id';
  static const String attestAssertionHeader = 'X-App-Attest-Assertion';
  static const List<String> headerNames = [
    integrityTokenHeader,
    attestKeyIdHeader,
    attestAssertionHeader,
  ];

  /// Attestation endpoints. Requests under this prefix are never checked.
  static const String attestPathPrefix = '/api/v1/misc/app-attest/';
  static const String _challengePath = 'api/v1/misc/app-attest/challenge';
  static const String _attestPath = 'api/v1/misc/app-attest/attest';

  static const Duration _tokenTimeout = Duration(seconds: 15);
  static const Duration _assertionTimeout = Duration(seconds: 10);
  static const Duration _attestationWait = Duration(seconds: 45);

  /// After a failed attestation, requests go out unsigned for this long
  /// instead of each re-running the (slow, networked) attestation.
  static const Duration _attestCooldown = Duration(seconds: 30);

  /// A 403 asking to re-verify may bypass the cooldown, but not more often
  /// than this, so enforce mode can't turn every request into an attestation.
  static const Duration _forcedAttestFloor = Duration(seconds: 5);

  // iOS state (this isolate).
  bool _attestUnsupported = false;
  String? _attestedKeyId;
  Future<String?>? _attesting;
  DateTime? _attestFailedAt;

  bool get _isAndroid => _platformIs(() => Platform.isAndroid);
  bool get _isIos => _platformIs(() => Platform.isIOS);

  static bool _platformIs(bool Function() check) {
    try {
      return check();
    } catch (_) {
      return false; // Platform unavailable (tests).
    }
  }

  /// Starts preparing the Play Integrity provider so the first request isn't
  /// slowed by it. Fire-and-forget.
  void warmUp() {
    if (!_isAndroid) return;
    AppIntegrityPlatform.preparePlayIntegrity(cloudProjectNumber).catchError(
      (Object e) => AppLogger.d('[Integrity] Play Integrity prepare failed: $e'),
    );
  }

  /// Whether to attach a proof to [options]: every API request except the
  /// attestation endpoints themselves (they create the key that signs the
  /// rest). Deliberately not narrowed to the backend's current rules (Domain,
  /// Request-Origin, exempt paths) — those are the backend's to change, and a
  /// proof it doesn't need is ignored.
  bool appliesTo(RequestOptions options) {
    if (!_isAndroid && !_isIos) return false;
    return !options.uri.path.contains(attestPathPrefix);
  }

  /// Integrity headers for [options]; empty when none could be produced.
  /// [dio] runs the attestation calls on iOS.
  Future<Map<String, String>> headersFor(RequestOptions options, Dio dio) {
    if (_isAndroid) return _playIntegrityHeaders();
    if (_isIos) return _appAttestHeaders(options, dio);
    return Future.value(const {});
  }

  /// Handles the backend's "verify again" answer: forgets the key that was
  /// sent ([sentKeyId], if any) so the next request attests a new one.
  Future<void> invalidateAttestation(String? sentKeyId) async {
    if (!_isIos) return;
    if (sentKeyId != null) {
      if (_attestedKeyId == sentKeyId) _attestedKeyId = null;
      try {
        await AppIntegrityPlatform.resetAppAttest(keyId: sentKeyId);
      } catch (e) {
        AppLogger.d('[Integrity] App Attest reset failed: $e');
      }
    }
    final failedAt = _attestFailedAt;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) >= _forcedAttestFloor) {
      _attestFailedAt = null;
    }
  }

  // ---------------------------------------------------------------- Android

  Future<Map<String, String>> _playIntegrityHeaders() async {
    try {
      final token = await AppIntegrityPlatform.requestPlayIntegrityToken(
        cloudProjectNumber,
      ).timeout(_tokenTimeout);
      return {integrityTokenHeader: token};
    } catch (e) {
      AppLogger.d('[Integrity] no Play Integrity token: $e');
      return const {};
    }
  }

  // -------------------------------------------------------------------- iOS

  Future<Map<String, String>> _appAttestHeaders(
    RequestOptions options,
    Dio dio,
  ) async {
    // "<METHOD> <path>": path as sent, trailing slash kept, no query/host.
    final clientData = '${options.method.toUpperCase()} ${options.uri.path}';

    for (var attempt = 0; attempt < 2; attempt++) {
      final keyId = await _ensureAttestedKey(dio);
      if (keyId == null) return const {};
      try {
        final assertion = await AppIntegrityPlatform.generateAssertion(
          keyId,
          clientData,
        ).timeout(_assertionTimeout);
        return {attestKeyIdHeader: keyId, attestAssertionHeader: assertion};
      } on PlatformException catch (e) {
        // The Secure Enclave key is gone (restored to a new device, …):
        // forget it and attest a fresh one, once.
        if (e.code != AppIntegrityError.invalidKey) {
          AppLogger.d('[Integrity] assertion failed: ${e.code}');
          return const {};
        }
        await invalidateAttestation(keyId);
      } catch (e) {
        AppLogger.d('[Integrity] assertion failed: $e');
        return const {};
      }
    }
    return const {};
  }

  /// The attested key id, attesting one first if needed. Single-flight: API
  /// calls queue behind one in-flight attestation. `null` when unavailable.
  Future<String?> _ensureAttestedKey(Dio dio) async {
    if (_attestUnsupported) {
      AppLogger.d('[Integrity] App Attest unsupported on this device '
          '(simulator?) — request sent without assertion');
      return null;
    }
    final cached = _attestedKeyId;
    if (cached != null) return cached;

    final failedAt = _attestFailedAt;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < _attestCooldown) {
      AppLogger.d('[Integrity] attestation failed recently — request sent '
          'without assertion (cooldown)');
      return null;
    }

    final inFlight = _attesting ??= _attest(dio).whenComplete(() {
      _attesting = null;
    });
    // Don't hold a request forever if Apple or the backend hangs; the
    // attestation itself keeps going for the requests after it.
    return inFlight.timeout(
      _attestationWait,
      onTimeout: () {
        AppLogger.d('[Integrity] attestation still running after '
            '${_attestationWait.inSeconds}s — request sent without assertion');
        return null;
      },
    );
  }

  Future<String?> _attest(Dio dio) async {
    try {
      final state = await AppIntegrityPlatform.appAttestState();
      if (!state.supported) {
        // Simulator / unsupported hardware: nothing will ever succeed.
        _attestUnsupported = true;
        return null;
      }
      if (state.keyId != null && state.attested) {
        return _attestedKeyId = state.keyId;
      }

      var keyId = await AppIntegrityPlatform.generateKey();
      var challengeRetried = false;
      var keyRotated = false;

      while (true) {
        final challenge = await _fetchChallenge(dio);

        final String attestation;
        try {
          attestation = await AppIntegrityPlatform.attestKey(keyId, challenge);
        } on PlatformException catch (e) {
          // Key unusable (e.g. already attested by Apple before an earlier
          // run died before the backend confirmed): rotate once.
          if (e.code == AppIntegrityError.invalidKey && !keyRotated) {
            keyRotated = true;
            keyId = await AppIntegrityPlatform.generateKey(replacing: keyId);
            continue;
          }
          rethrow;
        }

        final outcome = await _registerAttestation(
          dio,
          keyId: keyId,
          attestation: attestation,
          challenge: challenge,
        );
        switch (outcome) {
          case _AttestOutcome.ok:
            await AppIntegrityPlatform.markAttested(keyId);
            _attestFailedAt = null;
            return _attestedKeyId = keyId;
          case _AttestOutcome.challengeExpired when !challengeRetried:
            challengeRetried = true;
            continue;
          case _AttestOutcome.attestationFailed when !keyRotated:
            keyRotated = true;
            keyId = await AppIntegrityPlatform.generateKey(replacing: keyId);
            continue;
          default:
            throw StateError('attestation rejected: $outcome');
        }
      }
    } catch (e) {
      AppLogger.d('[Integrity] App Attest attestation failed: $e');
      _attestFailedAt = DateTime.now();
      return null;
    }
  }

  /// A fresh, single-use challenge (valid for 5 minutes).
  Future<String> _fetchChallenge(Dio dio) async {
    final response = await dio.get<dynamic>(
      _challengePath,
      options: Options(extra: {ErrorInterceptor.silentKey: true}),
    );
    final data = response.data;
    final body = data is Map ? data['body'] : null;
    final challenge = body is Map ? body['challenge'] : null;
    if (challenge is! String || challenge.isEmpty) {
      throw StateError('challenge missing from response');
    }
    return challenge;
  }

  Future<_AttestOutcome> _registerAttestation(
    Dio dio, {
    required String keyId,
    required String attestation,
    required String challenge,
  }) async {
    try {
      await dio.post<dynamic>(
        _attestPath,
        data: {
          'key_id': keyId,
          'attestation': attestation,
          'challenge': challenge,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          extra: {ErrorInterceptor.silentKey: true},
        ),
      );
      return _AttestOutcome.ok;
    } on DioException catch (e) {
      final data = e.response?.data;
      final exception = data is Map ? data['exception'] : null;
      if (e.response?.statusCode == 400 && exception is String) {
        switch (exception.trim()) {
          case 'Challenge is invalid or has expired.':
            return _AttestOutcome.challengeExpired;
          case 'Device attestation failed.':
            return _AttestOutcome.attestationFailed;
        }
      }
      AppLogger.d(
        '[Integrity] attest rejected (${e.response?.statusCode}): $exception',
      );
      return _AttestOutcome.rejected;
    }
  }
}

enum _AttestOutcome { ok, challengeExpired, attestationFailed, rejected }

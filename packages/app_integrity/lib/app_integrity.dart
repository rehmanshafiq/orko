import 'package:flutter/services.dart';

/// Thin Dart wrapper over the native `orko/app_integrity` channel.
///
/// Every method throws [PlatformException] on failure; its `code` is one of
/// the [AppIntegrityError] values (or a Play Integrity error code number on
/// Android). Policy — when to call what, retries, caching — lives in the app.
class AppIntegrityPlatform {
  const AppIntegrityPlatform._();

  static const MethodChannel _channel = MethodChannel('orko/app_integrity');

  // ---------------------------------------------------------------- Android

  /// Warms up the process-wide Play Integrity token provider. Safe to call
  /// repeatedly; concurrent calls share one preparation.
  static Future<void> preparePlayIntegrity(int cloudProjectNumber) {
    return _channel.invokeMethod<void>('prepare', {
      'cloudProjectNumber': cloudProjectNumber,
    });
  }

  /// A fresh Play Integrity standard-request token. Prepares the provider
  /// first if needed and transparently re-prepares once when the provider
  /// has become invalid.
  static Future<String> requestPlayIntegrityToken(int cloudProjectNumber) async {
    final token = await _channel.invokeMethod<String>('requestToken', {
      'cloudProjectNumber': cloudProjectNumber,
    });
    if (token == null || token.isEmpty) {
      throw PlatformException(code: AppIntegrityError.unknown);
    }
    return token;
  }

  // -------------------------------------------------------------------- iOS

  /// Current App Attest state persisted in the Keychain.
  static Future<AppAttestState> appAttestState() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('state');
    return AppAttestState(
      supported: map?['supported'] == true,
      keyId: map?['keyId'] as String?,
      attested: map?['attested'] == true,
    );
  }

  /// Returns the stored key id, generating (and storing) a new key when there
  /// is none or when the stored one equals [replacing]. Compare-and-swap, so
  /// two engines racing to rotate the same key end up sharing one new key.
  static Future<String> generateKey({String? replacing}) async {
    final keyId = await _channel.invokeMethod<String>('generateKey', {
      'replacing': replacing,
    });
    return keyId!;
  }

  /// Apple attestation of [keyId] over SHA256(UTF-8 [challenge]), base64.
  static Future<String> attestKey(String keyId, String challenge) async {
    final attestation = await _channel.invokeMethod<String>('attestKey', {
      'keyId': keyId,
      'challenge': challenge,
    });
    return attestation!;
  }

  /// Records that the backend accepted [keyId]. Ignored if the stored key has
  /// since changed.
  static Future<void> markAttested(String keyId) {
    return _channel.invokeMethod<void>('markAttested', {'keyId': keyId});
  }

  /// Forgets the stored key and attested flag — only when the stored key is
  /// still [keyId] (or unconditionally when [keyId] is null).
  static Future<void> resetAppAttest({String? keyId}) {
    return _channel.invokeMethod<void>('reset', {'keyId': keyId});
  }

  /// Assertion by [keyId] over SHA256(UTF-8 [clientData]), base64.
  static Future<String> generateAssertion(String keyId, String clientData) async {
    final assertion = await _channel.invokeMethod<String>('generateAssertion', {
      'keyId': keyId,
      'clientData': clientData,
    });
    return assertion!;
  }
}

/// Error codes the native side reports.
class AppIntegrityError {
  const AppIntegrityError._();

  /// App Attest unavailable (simulator, iOS < 14, some Macs).
  static const String unsupported = 'unsupported';

  /// The App Attest key no longer exists (restore to new device, reinstall).
  static const String invalidKey = 'invalid_key';

  /// Apple's attestation service is temporarily unreachable.
  static const String serverUnavailable = 'server_unavailable';

  static const String invalidInput = 'invalid_input';
  static const String unknown = 'unknown';
}

class AppAttestState {
  const AppAttestState({
    required this.supported,
    required this.keyId,
    required this.attested,
  });

  final bool supported;
  final String? keyId;
  final bool attested;
}

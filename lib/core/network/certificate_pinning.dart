import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// TLS certificate pinning for the app's API client.
///
/// Pins the connection's trust anchor to the CA intermediates bundled in
/// `assets/certs/api_ca_bundle.pem` (currently DigiCert "GeoTrust TLS RSA CA
/// G1" for production and Google "WR3" for staging). By building the API Dio's
/// `HttpClient` with `withTrustedRoots: false` and ONLY those anchors trusted,
/// a TLS session that does not chain to one of them — e.g. a MITM proxy using
/// a user-installed or otherwise untrusted CA — fails the handshake.
///
/// Pinning the CA intermediate (rather than the leaf) means routine leaf-cert
/// renewals keep working; the pins only need updating if the server's issuing
/// CA changes. When that happens, regenerate the bundle and ship an app update:
///
///   for H in apis-py.orkofleet.com staging-python.orkofleet.com; do \
///     echo | openssl s_client -connect $H:443 -servername $H -showcerts; done
///   # save each intermediate (2nd cert) into assets/certs/api_ca_bundle.pem
///
/// Only the API Dio uses this adapter; Google Places, Firebase and the receipt
/// blob host use their own clients and keep default system trust.
class CertificatePinning {
  const CertificatePinning._();

  static const String _bundleAsset = 'assets/certs/api_ca_bundle.pem';

  static List<int>? _caBytes;

  /// Loads the pinned CA bundle into memory. Call once in `main()` before the
  /// first API request.
  ///
  /// Pinning is intentionally skipped in debug builds so developers can proxy
  /// traffic (Charles/mitmproxy) during development. If the bundle can't be
  /// read (a packaging error), pinning stays off rather than bricking the app —
  /// enforcement only happens when the bundle loads successfully.
  static Future<void> load() async {
    if (kDebugMode) return;
    try {
      final data = await rootBundle.load(_bundleAsset);
      _caBytes = data.buffer.asUint8List();
    } catch (_) {
      _caBytes = null;
    }
  }

  /// Returns a pinned [IOHttpClientAdapter], or `null` when pinning is inactive
  /// (debug build or bundle unavailable) so the caller keeps Dio's default
  /// adapter.
  static IOHttpClientAdapter? adapter() {
    final bytes = _caBytes;
    if (bytes == null) return null;
    return IOHttpClientAdapter(
      createHttpClient: () {
        final context = SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificatesBytes(bytes);
        return HttpClient(context: context);
      },
    );
  }
}

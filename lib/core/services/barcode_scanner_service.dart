import 'package:flutter/material.dart';
import 'package:orko_hubco/core/utils/widgets/qr_scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of launching the booking QR scanner.
sealed class BookingQrScanResult {
  const BookingQrScanResult();
}

final class BookingQrScanSuccess extends BookingQrScanResult {
  const BookingQrScanSuccess(this.code);

  final String code;
}

final class BookingQrScanCancelled extends BookingQrScanResult {
  const BookingQrScanCancelled();
}

final class BookingQrScanPermissionDenied extends BookingQrScanResult {
  const BookingQrScanPermissionDenied();
}

final class BookingQrScanFailure extends BookingQrScanResult {
  const BookingQrScanFailure(this.message);

  final String message;
}

/// Opens a camera-based QR scanner for upcoming bookings using `mobile_scanner`
/// (no license key required).
class BarcodeScannerService {
  BarcodeScannerService._();

  static Future<BookingQrScanResult> scanBookingQrCode(
    BuildContext context,
  ) async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return const BookingQrScanPermissionDenied();
    }
    if (!context.mounted) return const BookingQrScanCancelled();

    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (code == null) return const BookingQrScanCancelled();
    if (code.isEmpty) return const BookingQrScanFailure('No QR code detected');
    return BookingQrScanSuccess(code);
  }
}

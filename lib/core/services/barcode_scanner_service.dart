import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

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

/// Opens a camera-based QR scanner for upcoming bookings using
/// `simple_barcode_scanner` (no license key required).
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

    // SimpleBarcodeScannerPage pops with the scanned string, or the sentinel
    // '-1' when the user cancels / backs out.
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const SimpleBarcodeScannerPage(
          scanType: ScanType.qr,
          appBarTitle: 'Scan QR Code',
          centerTitle: true,
          isShowFlashIcon: true,
          cancelButtonText: 'Cancel',
        ),
      ),
    );

    if (scanned == null || scanned == '-1') {
      return const BookingQrScanCancelled();
    }
    final code = scanned.trim();
    if (code.isEmpty) return const BookingQrScanFailure('No QR code detected');
    return BookingQrScanSuccess(code);
  }
}

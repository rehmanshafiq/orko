import 'package:barcode_scanner/scanbot_barcode_sdk.dart';
import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
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

/// Opens the Scanbot barcode scanner for QR codes on upcoming bookings.
class BarcodeScannerService {
  BarcodeScannerService._();

  static bool _initialized = false;

  /// Initializes Scanbot SDK. Empty [licenseKey] uses the built-in trial mode.
  static Future<void> initialize({String licenseKey = ''}) async {
    if (_initialized) return;

    await ScanbotBarcodeSdk.initialize(
      SdkConfiguration(licenseKey: licenseKey),
    );

    _initialized = true;
  }

  static ScanbotColor get _brandPrimary =>
      ScanbotColor(_toScanbotHex(AppColors.primaryDarkColor));

  static String _toScanbotHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Future<BookingQrScanResult> scanBookingQrCode() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return const BookingQrScanPermissionDenied();
    }

    final configuration = BarcodeScannerScreenConfiguration()
      ..palette.sbColorPrimary = _brandPrimary
      ..topBar.backgroundColor = _brandPrimary
      ..useCase = SingleScanningMode()
      ..userGuidance.title.text = 'Point your camera at the QR code'
      ..scannerConfiguration = BarcodeScannerConfiguration(
        barcodeFormatConfigurations: [
          BarcodeFormatCommonTwoDConfiguration(
            formats: [BarcodeFormat.QR_CODE],
          ),
        ],
      );

    final result = await ScanbotBarcodeSdk.barcode.startScanner(configuration);

    return switch (result) {
      Ok(:final value) => () {
          try {
            final code = value.items.isNotEmpty
                ? value.items.first.barcode.text.trim()
                : '';
            if (code.isEmpty) {
              return const BookingQrScanFailure('No QR code detected');
            }
            return BookingQrScanSuccess(code);
          } finally {
            value.release();
          }
        }(),
      Cancel() => const BookingQrScanCancelled(),
      Error(:final error) => BookingQrScanFailure(error.message),
    };
  }
}

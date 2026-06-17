import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Full-screen camera QR scanner backed by `mobile_scanner`.
///
/// Pops with the trimmed QR string on the first successful detection, or with
/// `null` if the user backs out without scanning.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDarkColor,
        foregroundColor: AppColors.whiteColor,
        elevation: 0,
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            tooltip: 'Toggle flash',
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flash_on
                    : Icons.flash_off,
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final windowSide = size.shortestSide * 0.7;
          final scanWindow = Rect.fromCenter(
            center: size.center(Offset.zero),
            width: windowSide,
            height: windowSide,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                scanWindow: scanWindow,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to start the camera.\n${error.errorDetails?.message ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.whiteColor),
                    ),
                  ),
                ),
              ),
              // Dim everything outside the scan window.
              CustomPaint(
                size: size,
                painter: _ScannerOverlayPainter(scanWindow),
              ),
              // Brand-colored frame around the scan window.
              Positioned.fromRect(
                rect: scanWindow,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryLightColor,
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: scanWindow.bottom + 24,
                child: const Text(
                  'Point your camera at the QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints a translucent scrim over the whole screen with the [scanWindow]
/// punched out, so the camera feed shows clearly inside the rectangle.
class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter(this.scanWindow);

  final Rect scanWindow;
  static const double radius = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(scanWindow, Radius.circular(radius)),
      );
    final scrim = Path.combine(PathOperation.difference, background, hole);
    canvas.drawPath(scrim, Paint()..color = AppColors.blackColor.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanWindow != scanWindow;
}

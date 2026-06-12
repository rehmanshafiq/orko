import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/utils/booking_receipt_pdf.dart';

/// Generates the booking receipt PDF and opens the system save/share sheet so
/// the user can download it. Shows an inline spinner while building.
class DownloadReceiptButton extends StatefulWidget {
  const DownloadReceiptButton({
    super.key,
    required this.bookingRef,
    required this.stationName,
    required this.slotLabel,
    required this.paymentLabel,
    required this.amountPaid,
  });

  final String bookingRef;
  final String stationName;
  final String slotLabel;
  final String paymentLabel;
  final int amountPaid;

  @override
  State<DownloadReceiptButton> createState() => _DownloadReceiptButtonState();
}

class _DownloadReceiptButtonState extends State<DownloadReceiptButton> {
  bool _isGenerating = false;

  Future<void> _onDownload() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await BookingReceiptPdf.download(
        bookingRef: widget.bookingRef,
        stationName: widget.stationName,
        slotLabel: widget.slotLabel,
        paymentLabel: widget.paymentLabel,
        amountPaid: widget.amountPaid,
      );
    } catch (e, st) {
      debugPrint('❌ Receipt PDF failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: AppText('Could not generate the receipt. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 42.h,
      child: OutlinedButton(
        onPressed: _isGenerating ? null : _onDownload,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ui.brandPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.r),
          ),
          foregroundColor: ui.brandPrimary,
        ),
        child: _isGenerating
            ? SizedBox(
                height: 20.r,
                width: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ui.brandPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 19.r,
                    color: ui.textSecondary,
                  ),
                  8.horizontalSpace,
                  AppText(
                    'Download Receipt (PDF)',
                    color: ui.textSecondary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/session_summary_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/utils/session_receipt_downloader.dart';

/// Downloads the server-generated receipt for the current session: asks the
/// backend for the receipt URL (`download-receipt/<sessionId>`), fetches the
/// PDF, then opens the system save/share sheet. Shows an inline spinner while
/// working and a SnackBar on any failure.
class SessionReceiptDownloadButton extends StatefulWidget {
  const SessionReceiptDownloadButton({super.key, required this.sessionId});

  /// Used only to name the downloaded file — the cubit already knows which
  /// session to request the receipt for.
  final int sessionId;

  @override
  State<SessionReceiptDownloadButton> createState() =>
      _SessionReceiptDownloadButtonState();
}

class _SessionReceiptDownloadButtonState
    extends State<SessionReceiptDownloadButton> {
  bool _isDownloading = false;

  Future<void> _onDownload() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    // Capture the messenger before the first await so we don't touch
    // `context` across async gaps after a possible dispose.
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await context.read<SessionSummaryCubit>().fetchReceiptUrl();
      if (!mounted) return;

      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        _showMessage(messenger, failure.message);
        return;
      }

      final url = result.getOrElse(() => '');
      await SessionReceiptDownloader.downloadAndShare(
        receiptUrl: url,
        sessionId: widget.sessionId,
      );
    } on ReceiptDownloadException catch (e) {
      if (mounted) _showMessage(messenger, e.message);
    } catch (e) {
      if (mounted) {
        _showMessage(
          messenger,
          'Could not download the receipt. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: AppText(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return SizedBox(
      width: double.infinity,
      height: 42.h,
      child: OutlinedButton(
        onPressed: _isDownloading ? null : _onDownload,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ui.brandPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.r),
          ),
          foregroundColor: ui.brandPrimary,
        ),
        child: _isDownloading
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
                    'Download Receipt',
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

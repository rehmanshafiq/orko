import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_details_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/confirmation_header.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/download_receipt_button.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/info_banner.dart';

/// Receipt screen for a completed charging session from profile / history.
/// Mirrors [BookingSuccessMobileView] layout and PDF download flow.
class ChargingSessionReceiptMobileView extends StatelessWidget {
  const ChargingSessionReceiptMobileView({
    super.key,
    required this.session,
  });

  final ChargeSessionHistoryEntity session;

  String get _bookingRef => 'SESSION-${session.id}';

  String get _slotLabel => _sessionSlotLabel(session);

  int get _amountPaid => session.totalCost?.round() ?? 0;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: ui.textSecondary,
                    size: 24.r,
                  ),
                  padding: EdgeInsets.all(8.r),
                  constraints: BoxConstraints(
                    minWidth: 40.w,
                    minHeight: 40.h,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppUtils.horizontal16Padding,
                child: Column(
                  children: [
                    36.verticalSpace,
                    ConfirmationHeader(
                      ui: ui,
                      title: 'Charging Receipt',
                      subtitle:
                          'Your charging session details are shown below.',
                    ),
                    28.verticalSpace,
                    BookingDetailsCard(
                      ui: ui,
                      bookingRef: _bookingRef,
                      stationName: session.displayName,
                      slotLabel: _slotLabel,
                      amountPaid: _amountPaid,
                    ),
                    20.verticalSpace,
                    InfoBanner(
                      ui: ui,
                      message: 'Keep this receipt for your records.',
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppUtils.horizontal16Padding.add(
                EdgeInsets.only(bottom: 12.h, top: 8.h),
              ),
              child: DownloadReceiptButton(
                bookingRef: _bookingRef,
                stationName: session.displayName,
                slotLabel: _slotLabel,
                paymentLabel: '—',
                amountPaid: _amountPaid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the slot line shown on the receipt — session date/time plus duration
/// when available.
String _sessionSlotLabel(ChargeSessionHistoryEntity session) {
  final dateLabel = _sessionDateLabel(session.startedAt);
  final duration = session.duration?.trim();
  if (duration != null && duration.isNotEmpty) {
    return '$dateLabel · $duration';
  }
  return dateLabel;
}

String _sessionDateLabel(String? raw) {
  if (raw == null || raw.isEmpty) return 'Date unavailable';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  return '${parsed.month}/${parsed.day}/${parsed.year} · '
      '${parsed.hour.toString().padLeft(2, '0')}:'
      '${parsed.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_details_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/confirmation_header.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/download_receipt_button.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/info_banner.dart';

/// Shown after a booking is created successfully. Mirrors the layout of
/// [BookingConfirmationMobileView] but omits the `Payment` row — every value in
/// the summary card is supplied dynamically by the booking screen.
class BookingSuccessMobileView extends StatelessWidget {
  const BookingSuccessMobileView({
    super.key,
    required this.bookingRef,
    required this.stationName,
    required this.slotLabel,
    required this.amountPaid,
  });

  final String bookingRef;
  final String stationName;
  final String slotLabel;
  final int amountPaid;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    // The success screen is pushed on top of the booking screen, so the Android
    // system back gesture would otherwise return there. Intercept the pop and
    // route home instead, matching the close button.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
        backgroundColor: ui.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => context.go('/home'),
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
                      ConfirmationHeader(ui: ui),
                      28.verticalSpace,
                      BookingDetailsCard(
                        ui: ui,
                        bookingRef: bookingRef,
                        stationName: stationName,
                        slotLabel: slotLabel,
                        amountPaid: amountPaid,
                      ),
                      20.verticalSpace,
                      InfoBanner(ui: ui),
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
                  bookingRef: bookingRef,
                  stationName: stationName,
                  slotLabel: slotLabel,
                  paymentLabel: '—',
                  amountPaid: amountPaid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

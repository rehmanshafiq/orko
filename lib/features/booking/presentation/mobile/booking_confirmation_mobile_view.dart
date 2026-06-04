import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_confirmation_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_confirmation_state.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_details_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/confirmation_header.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/info_banner.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/primary_action_button.dart';

/// Shown after successful payment — booking summary & return to bookings.
class BookingConfirmationMobileView extends StatelessWidget {
  const BookingConfirmationMobileView({super.key});

  static const String _bookingRef = 'BK-2025-04182';
  static const String _stationName = 'HGL Charging Hub M2';
  static const String _slotLabel = 'April 18 · 14:00 – 15:00';
  static const String _paymentLabel = 'Visa •••• 4242';

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<BookingConfirmationCubit, BookingConfirmationState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: AppUtils.horizontal16Padding,
                    child: Column(
                      children: [
                        36.verticalSpace,
                        ConfirmationHeader(ui: ui),
                        28.verticalSpace,
                        BookingDetailsCard(
                          ui: ui,
                          bookingRef: _bookingRef,
                          stationName: _stationName,
                          slotLabel: _slotLabel,
                          amountPaid: state.amountPaid,
                          paymentLabel: _paymentLabel,
                        ),
                        20.verticalSpace,
                        InfoBanner(ui: ui),
                        24.verticalSpace,
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: AppUtils.horizontal16Padding.add(
                EdgeInsets.only(bottom: 12.h, top: 8.h),
              ),
              child: PrimaryActionButton(

                onPressed: () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

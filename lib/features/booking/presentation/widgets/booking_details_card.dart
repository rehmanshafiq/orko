import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_detail_row.dart';

class BookingDetailsCard extends StatelessWidget {
  const BookingDetailsCard({
    super.key,
    required this.ui,
    required this.bookingRef,
    required this.stationName,
    required this.slotLabel,
    required this.amountPaid,
    required this.paymentLabel,
  });

  final AppUiColors ui;
  final String bookingRef;
  final String stationName;
  final String slotLabel;
  final int amountPaid;
  final String paymentLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingDetailRow(
            ui: ui,
            label: 'Booking ID',
            value: bookingRef,
            emphasizeValue: true,
          ),
          14.verticalSpace,
          Divider(
            height: 1,
            thickness: 1,
            color: ui.borderSubtle,
          ),
          14.verticalSpace,
          BookingDetailRow(ui: ui, label: 'Station', value: stationName),
          12.verticalSpace,
          BookingDetailRow(ui: ui, label: 'Slot', value: slotLabel),
          12.verticalSpace,
          BookingDetailRow(
            ui: ui,
            label: 'Amount paid',
            value: 'Rs $amountPaid',
          ),
          12.verticalSpace,
          BookingDetailRow(ui: ui, label: 'Payment', value: paymentLabel),
        ],
      ),
    );
  }
}

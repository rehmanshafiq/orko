import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_functions.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charger_compatibility_gate.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class ChargingStationBottomActionsWidget extends StatelessWidget {
  const ChargingStationBottomActionsWidget({
    super.key,
    required this.station,
    required this.latitude,
    required this.longitude,
    this.isEnabled = true,
    this.isClosed = false,
    this.chargePointId,
    this.openingTime = '',
    this.closingTime = '',
  });

  final HubcoLocationEntity station;
  final double latitude;
  final double longitude;
  final bool isEnabled;

  /// True when the station is closed (`is_closed` API key) — tapping Book Slot
  /// shows a "Coming soon" toast instead of proceeding to booking.
  final bool isClosed;

  /// The station's `charge_point_id`, used to verify vehicle compatibility
  /// before navigating to booking.
  final String? chargePointId;

  /// Raw station opening time (`HH:mm:ss`) used to grey out off-hours slots.
  final String openingTime;

  /// Raw station closing time (`HH:mm:ss`) used to grey out off-hours slots.
  final String closingTime;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38.h,
                child: OutlinedButton(
                  onPressed: isEnabled ? () => _openDirections(context) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ui.textPrimary,
                    side: BorderSide(
                      color: ui.textPrimary.withValues(
                        alpha: isEnabled ? 0.85 : 0.35,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation_rounded, size: 18.r),
                      8.horizontalSpace,
                      AppText(
                        'Directions',
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: PrimaryButtonWidget(
                text: 'Book Slot',
                leadingIcon: Icons.calendar_today_outlined,
                iconHeight: 18.sp,
                onPress: () => _onBookSlot(context),
                isEnabled: isEnabled,
                buttonWidth: double.infinity,
                buttonHeight: 38.h,
                cornerRadius: 24.r,
                gradientColors: const [
                  AppColors.primaryDarkColor,
                  AppColors.primaryDarkButtonColor,
                ],
                textColor: AppColors.whiteColor,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Guests must authenticate before booking — prompt to log in/sign up.
  /// Authenticated users go through the compatibility gate, which only proceeds
  /// to booking when their vehicle is compatible with this charger.
  void _onBookSlot(BuildContext context) {
    if (isClosed) {
      Fluttertoast.showToast(
        msg: 'Coming soon',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(context);
      return;
    }
    ChargerCompatibilityGate.run(
      context,
      station: station,
      chargePointId: chargePointId,
      openingTime: openingTime,
      closingTime: closingTime,
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    try {
      await AppFunctions.openGoogleMapsDirections(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }
}

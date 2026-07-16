import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Informational popup shown when a PHEV (Plug-in Hybrid) user plans a trip.
///
/// The planner only accounts for electric range, so a PHEV driver may need to
/// top up at a conventional fuel station along the way. Per product, this shows
/// every time a PHEV user taps Plan Trip.
class PhevNoticeDialog {
  PhevNoticeDialog._();

  /// Shows the notice. Resolves to `true` when the user chooses to continue and
  /// `false` if they cancel or dismiss the dialog.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _PhevNoticeDialogBody(
        onContinue: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
    return result ?? false;
  }
}

class _PhevNoticeDialogBody extends StatelessWidget {
  const _PhevNoticeDialogBody({
    required this.onContinue,
    required this.onCancel,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Dialog(
      backgroundColor: ui.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 56.r,
                width: 56.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.brandPrimary),
                ),
                child: Icon(
                  Icons.local_gas_station_outlined,
                  color: ui.brandPrimary,
                  size: 28.r,
                ),
              ),
            ),
            16.verticalSpace,
            AppText(
              'Hybrid (PHEV) Vehicle',
              textAlign: TextAlign.center,
              color: ui.textPrimary,
              fontSize: FontSizes.font18Sp,
              fontWeight: FontWeights.weight700,
            ),
            8.verticalSpace,
            AppText(
              'You may need to stop at a conventional fuel station, where petrol '
              'refuelling is available, as this plan currently shows only your '
              'electric (EV) range.',
              textAlign: TextAlign.center,
              color: ui.textMuted,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
            ),
            20.verticalSpace,
            PrimaryButtonWidget(
              text: 'Continue',
              onPress: onContinue,
              buttonHeight: 40.h,
              cornerRadius: 24.r,
              gradientColors: const [
                AppColors.primaryDarkColor,
                AppColors.primaryDarkButtonColor,
              ],
              textColor: AppColors.whiteColor,
              fontSize: FontSizes.font15Sp,
              fontWeight: FontWeights.weight600,
            ),
            4.verticalSpace,
            TextButton(
              onPressed: onCancel,
              child: AppText(
                'Cancel',
                color: ui.textMuted,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

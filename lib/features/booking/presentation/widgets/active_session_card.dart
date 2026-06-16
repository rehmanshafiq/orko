import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({
    super.key,
    required this.ui,
    required this.session,
    required this.onTap,
  });

  final AppUiColors ui;
  final ActiveSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: AppUtils.all18Padding,
        decoration: BoxDecoration(
          color: ui.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ui.brandPrimary.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44.r,
                  width: 44.r,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: ui.iconContainerOutline, width: 1.5),
                  ),
                  child: Icon(Icons.bolt, color: ui.brandPrimary, size: 22.sp),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        session.stationName,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font16Sp,
                        fontWeight: FontWeights.weight700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.verticalSpace,
                      AppText(
                        session.powerLabel,
                        color: ui.textSecondary,
                        fontSize: FontSizes.font13Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkColor,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: AppText(
                    'Charging',
                    color: AppColors.whiteColor,
                    fontSize: FontSizes.font11Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: session.progressPercent.clamp(0.0, 1.0),
                minHeight: 8.h,
                backgroundColor: ui.progressTrack,
                valueColor: AlwaysStoppedAnimation(ui.brandPrimary),
              ),
            ),
            10.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  '${session.energyDeliveredKwh} kWh delivered',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
                AppText(
                  session.startedAtLabel,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

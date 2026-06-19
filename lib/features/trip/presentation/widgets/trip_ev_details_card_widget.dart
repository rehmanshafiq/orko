import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripEvDetailsCardWidget extends StatelessWidget {
  const TripEvDetailsCardWidget({
    required this.currentBatteryPercent,
    super.key,
  });

  final double currentBatteryPercent;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    // Guests have no registered EV, so make/model and range are unavailable.
    final isGuest = AppStorage.isGuest;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.transparentColor,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _TripEvMetric(
                icon: _BatteryGlyph(percent: currentBatteryPercent),
                value: '${currentBatteryPercent.round()}%',
                label: 'current charge',
              ),
            ),
            _SectionDivider(color: ui.borderSubtle),
            Expanded(
              child: _TripEvMetric(
                icon: Icon(
                  Icons.directions_car_rounded,
                  size: 26.sp,
                  color: ui.brandSecondary,
                ),
                value: isGuest ? '-' : 'BYD',
                label: isGuest ? '-' : 'Atto 3',
              ),
            ),
            _SectionDivider(color: ui.borderSubtle),
            Expanded(
              child: _TripEvMetric(
                icon: _RangeGlyph(roadColor: ui.brandSecondary),
                value: isGuest ? '-' : '280 km',
                label: 'range',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      color: color,
    );
  }
}

class _TripEvMetric extends StatelessWidget {
  const _TripEvMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30.w,
          child: Center(child: icon),
        ),
        8.horizontalSpace,
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                value,
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              2.verticalSpace,
              AppText(
                label,
                color: ui.textMuted,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight400,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final fillFraction = (percent.clamp(0, 100)) / 100.0;
    final outlineColor = ui.brandSecondary;

    return SizedBox(
      width: 30.w,
      height: 16.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: outlineColor, width: 1.5),
              ),
              padding: EdgeInsets.all(1.5.r),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fillFraction,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ui.brandSecondary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 2.w,
            height: 7.h,
            margin: EdgeInsets.only(left: 1.w),
            decoration: BoxDecoration(
              color: outlineColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(1.r),
                bottomRight: Radius.circular(1.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeGlyph extends StatelessWidget {
  const _RangeGlyph({required this.roadColor});

  final Color roadColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.compare_arrows_rounded,
          size: 14.sp,
          color: roadColor,
        ),
        2.verticalSpace,
        _RoadShape(color: roadColor),
      ],
    );
  }
}

class _RoadShape extends StatelessWidget {
  const _RoadShape({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final railWidth = 2.w;
    return SizedBox(
      width: 16.w,
      height: 18.h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: railWidth, color: color),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: railWidth, color: color),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: List.generate(
                3,
                (_) => Container(
                  width: railWidth,
                  height: 3.h,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

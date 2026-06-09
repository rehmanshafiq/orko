import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// "Current Battery" slider: bold title with the live percentage on the right
/// and a track with a white, hollow (bordered) thumb. Colors follow the app
/// theme via [AppUiColors].
class TripCurrentBatterySliderWidget extends StatelessWidget {
  const TripCurrentBatterySliderWidget({
    required this.currentBatteryPercent,
    required this.onChanged,
    super.key,
  });

  final double currentBatteryPercent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'Current Battery',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            8.horizontalSpace,
            AppText(
              '${currentBatteryPercent.round()}%',
              color: ui.brandPrimary,
              fontSize: FontSizes.font16Sp,
              fontWeight: FontWeights.weight700,
            ),
          ],
        ),
        6.verticalSpace,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.h,
            trackShape: const RoundedRectSliderTrackShape(),
            activeTrackColor: ui.brandPrimary,
            inactiveTrackColor: ui.progressTrack,
            thumbShape: _HollowSliderThumbShape(
              radius: 11.r,
              borderColor: ui.brandPrimary,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
            overlayColor: WidgetStateColor.resolveWith(
              (_) => ui.brandPrimary.withValues(alpha: 0.16),
            ),
          ),
          child: Slider(
            value: currentBatteryPercent.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: (v) => onChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }
}

/// A white, filled circular thumb with a colored ring and a soft shadow —
/// the "hollow" look from the reference design.
class _HollowSliderThumbShape extends SliderComponentShape {
  const _HollowSliderThumbShape({
    required this.radius,
    required this.borderColor,
  });

  final double radius;
  final Color borderColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Soft shadow under the thumb.
    canvas.drawCircle(
      center.translate(0, 1),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // White fill.
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // Colored ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

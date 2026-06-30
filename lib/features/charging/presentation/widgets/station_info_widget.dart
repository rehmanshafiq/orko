import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class StationInfoWidget extends StatefulWidget {
  const StationInfoWidget({
    super.key,
    required this.infoText,
    required this.ui,
    this.operatingHours = '',
    this.pricing = '',
    this.contact = '',
  });

  final String infoText;
  final AppUiColors ui;

  /// Expandable details, pulled from the live-session response. Each row is
  /// hidden when its value is empty.
  final String operatingHours;
  final String pricing;
  final String contact;

  @override
  State<StationInfoWidget> createState() => _StationInfoWidgetState();
}

class _StationInfoWidgetState extends State<StationInfoWidget> {
  bool _expanded = false;

  bool get _hasDetails =>
      widget.operatingHours.isNotEmpty ||
      widget.pricing.isNotEmpty ||
      widget.contact.isNotEmpty;

  void _toggle() {
    if (!_hasDetails) return;
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    return Container(
      decoration: BoxDecoration(
        color: ui.searchBackground.withValues(alpha: ui.isLight ? 1 : null),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: AppUtils.vertical10Horizontal8Padding,
              child: Row(
                children: [
                  Expanded(child: _infoText()),
                  8.horizontalSpace,
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ui.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _details(ui),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _details(AppUiColors ui) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: ui.borderSubtle, height: 1),
          12.verticalSpace,
          if (widget.operatingHours.isNotEmpty)
            _DetailRow(
              ui: ui,
              icon: Icons.schedule_rounded,
              label: 'Operating Hours',
              value: widget.operatingHours,
            ),
          if (widget.pricing.isNotEmpty) ...[
            if (widget.operatingHours.isNotEmpty) 10.verticalSpace,
            _DetailRow(
              ui: ui,
              icon: Icons.local_offer_outlined,
              label: 'Pricing',
              value: widget.pricing,
            ),
          ],
          if (widget.contact.isNotEmpty) ...[
            if (widget.operatingHours.isNotEmpty || widget.pricing.isNotEmpty)
              10.verticalSpace,
            _DetailRow(
              ui: ui,
              icon: Icons.call_outlined,
              label: 'Contact No.',
              value: widget.contact,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoText() {
    final ui = widget.ui;
    final infoText = widget.infoText;
    const separator = ' - ';
    final separatorIndex = infoText.indexOf(separator);

    if (separatorIndex == -1) {
      return AppText(
        infoText,
        color: AppColors.whiteColor,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight400,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final prefix = infoText.substring(0, separatorIndex + separator.length);
    final stationName = infoText.substring(separatorIndex + separator.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight400,
          fontFamily: AppFonts.lexend,
        ),
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(color: ui.textSecondary),
          ),
          TextSpan(
            text: stationName,
            style: TextStyle(color: ui.textSecondaryWhite),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.ui,
    required this.icon,
    required this.label,
    required this.value,
  });

  final AppUiColors ui;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: ui.brandPrimary, size: 18.sp),
        10.horizontalSpace,
        AppText(
          label,
          color: ui.textSecondary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight500,
        ),
        12.horizontalSpace,
        Expanded(
          child: AppText(
            value,
            textAlign: TextAlign.right,
            color: ui.textSecondaryWhite,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

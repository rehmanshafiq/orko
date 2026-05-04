import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// EV map filters — matches product UI (dark sheet, green accents).
class MapFiltersBottomSheet extends StatefulWidget {
  const MapFiltersBottomSheet({
    super.key,
    required this.stationCount,
  });

  final int stationCount;

  static Future<void> show(
    BuildContext context, {
    required int stationCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) => MapFiltersBottomSheet(stationCount: stationCount),
    );
  }

  @override
  State<MapFiltersBottomSheet> createState() => _MapFiltersBottomSheetState();
}

class _MapFiltersBottomSheetState extends State<MapFiltersBottomSheet> {
  static const List<String> _chargerTypes = [
    'Type 1',
    'Type 2',
    'CCS',
    'CHAdeMO',
    'GB/T',
  ];

  static const List<String> _amenities = [
    'WiFi',
    'Restroom',
    'Cafe',
    'Parking',
    'Restaurant',
    '24 Hours',
  ];

  /// Initial state aligned with design reference.
  final Set<String> _selectedChargers = {'Type 2', 'CCS'};
  RangeValues _powerRange = const RangeValues(50, 150);
  bool _availableNow = true;
  final Set<String> _selectedAmenities = {'WiFi', 'Restroom'};
  RangeValues _priceRange = const RangeValues(30, 80);

  static const double _powerMin = 0;
  static const double _powerMax = 350;
  static const double _priceMin = 10;
  static const double _priceMax = 120;

  void _reset() {
    setState(() {
      _selectedChargers.clear();
      _powerRange = const RangeValues(_powerMin, _powerMax);
      _availableNow = false;
      _selectedAmenities.clear();
      _priceRange = const RangeValues(_priceMin, _priceMax);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        child: Container(
          width: double.infinity,
          color: ui.cardBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset + 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                10.verticalSpace,
                Center(
                  child: Container(
                    height: 4.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: ui.textSecondary.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                14.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Filters',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font20Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                      GestureDetector(
                        onTap: _reset,
                        child: AppText(
                          'Reset',
                          color: AppColors.primaryDarkColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                      ),
                    ],
                  ),
                ),
                12.verticalSpace,
                Divider(
                  height: 1,
                  thickness: 1,
                  color: ui.borderSubtle,
                ),
                18.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionTitle('Charger Type'),
                      10.verticalSpace,
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _chargerTypes.map((t) {
                            final selected = _selectedChargers.contains(t);
                            return Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedChargers.remove(t);
                                  } else {
                                    _selectedChargers.add(t);
                                  }
                                }),
                                child: _chargerChip(t, selected),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      22.verticalSpace,
                      _sectionTitle('Power Output'),
                      8.verticalSpace,
                      _powerLabelsRow(),
                      6.verticalSpace,
                      _rangeSlider(
                        values: _powerRange,
                        min: _powerMin,
                        max: _powerMax,
                        onChanged: (v) => setState(() => _powerRange = v),
                      ),
                      20.verticalSpace,
                      _sectionTitle('Availability'),
                      10.verticalSpace,
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              'Available Now',
                              color: ui.textPrimary,
                              fontSize: FontSizes.font14Sp,
                              fontWeight: FontWeights.weight500,
                            ),
                          ),
                          if (_availableNow) ...[
                            Container(
                              width: 6.w,
                              height: 6.w,
                              margin: EdgeInsets.only(right: 8.w),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryDarkColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          _availabilitySwitch(),
                        ],
                      ),
                      22.verticalSpace,
                      _sectionTitle('Amenities'),
                      12.verticalSpace,
                      _amenitiesGrid(),
                      22.verticalSpace,
                      _sectionTitle('Price Range'),
                      8.verticalSpace,
                      _priceLabelsRow(),
                      6.verticalSpace,
                      _rangeSlider(
                        values: _priceRange,
                        min: _priceMin,
                        max: _priceMax,
                        onChanged: (v) => setState(() => _priceRange = v),
                      ),
                    ],
                  ),
                ),
                20.verticalSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: _applyButton(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return AppText(
      text,
      color: AppUiColors.of(context).textPrimary,
      fontSize: FontSizes.font15Sp,
      fontWeight: FontWeights.weight700,
    );
  }

  Widget _chargerChip(String label, bool selected) {
    final ui = AppUiColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: selected
              ? AppColors.primaryDarkColor
              : ui.borderSubtle,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primaryDarkColor.withValues(alpha: 0.42),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: AppText(
        label,
        color: selected
            ? AppColors.primaryDarkColor
            : ui.textPrimary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }

  Widget _powerLabelsRow() {
    final ui = AppUiColors.of(context);
    final low = _powerRange.start.round();
    final high = _powerRange.end.round();
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              '0 kW',
              color: ui.textPrimary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Center(
            child: AppText(
              '$low kW - $high kW',
              color: AppColors.primaryDarkColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: AppText(
              '350 kW',
              color: ui.textPrimary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceLabelsRow() {
    final left = _priceRange.start.round();
    final right = _priceRange.end.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Rs $left per kWh',
          color: AppColors.primaryDarkColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        AppText(
          'Rs $right per kWh',
          color: AppColors.primaryDarkColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
      ],
    );
  }

  Widget _rangeSlider({
    required RangeValues values,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<RangeValues> onChanged,
  }) {
    final ui = AppUiColors.of(context);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        rangeThumbShape: RoundRangeSliderThumbShape(
          enabledThumbRadius: 10.r,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
        trackHeight: 4.h,
        activeTrackColor: AppColors.primaryDarkColor,
        inactiveTrackColor: ui.progressTrack,
        thumbColor: AppColors.primaryDarkColor,
      ),
      child: RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _availabilitySwitch() {
    final ui = AppUiColors.of(context);
    return SwitchTheme(
      data: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const Color(0xFF1A1C1B);
          }
          return AppColors.whiteColor.withValues(alpha: 0.85);
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return AppColors.primaryDarkColor;
          }
          return ui.progressTrack;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      child: Switch(
        value: _availableNow,
        onChanged: (v) => setState(() => _availableNow = v),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _amenitiesGrid() {
    final ui = AppUiColors.of(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 2.35,
      children: _amenities.map((name) {
        final on = _selectedAmenities.contains(name);
        return GestureDetector(
          onTap: () => setState(() {
            if (on) {
              _selectedAmenities.remove(name);
            } else {
              _selectedAmenities.add(name);
            }
          }),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _amenityBox(on),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  name,
                  color: on
                      ? AppColors.primaryDarkColor
                      : ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _amenityBox(bool checked) {
    final ui = AppUiColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: checked ? AppColors.primaryDarkColor : Colors.transparent,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: checked
              ? AppColors.primaryDarkColor
              : ui.borderSubtle,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? Icon(
              Icons.check,
              size: 14.r,
              color: AppColors.whiteColor,
            )
          : null,
    );
  }

  Widget _applyButton(BuildContext context) {
    final count = widget.stationCount;
    final suffix = count == 1 ? 'station' : 'stations';

    return PrimaryButtonWidget(
      text: 'Apply Filters',
      subtitle: '$count $suffix found',
      onPress: () => Navigator.of(context).pop(),
      buttonWidth: double.infinity,
      buttonHeight: 64.h,
      cornerRadius: 16.r,
      buttonColor: AppColors.primaryDarkColor,
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

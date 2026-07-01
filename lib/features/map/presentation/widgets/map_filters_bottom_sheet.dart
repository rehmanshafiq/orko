import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/gradient_switch.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/domain/usecases/get_filter_options_usecase.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';

/// EV map filters — cities, power output & amenities come from the
/// `filter-options` API; applying reloads stations via the `nearest` API.
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
    // Capture the MapCubit from the calling context (under the provider) and
    // hand it to the modal route, which lives outside that subtree.
    final cubit = context.read<MapCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: MapFiltersBottomSheet(stationCount: stationCount),
      ),
    );
  }

  @override
  State<MapFiltersBottomSheet> createState() => _MapFiltersBottomSheetState();
}

class _MapFiltersBottomSheetState extends State<MapFiltersBottomSheet> {
  // Selections (initialised from the cubit's currently-applied filters).
  String? _selectedCity;
  double? _selectedPowerOutput;
  final Set<int> _selectedAmenityIds = {};
  bool _availableNow = false;
  late RangeValues _priceRange;

  // Slider bounds. Default until the `filter-options` API supplies real
  // `price_range` values, then overwritten in [_loadOptions].
  static const double _priceMinDefault = 0;
  static const double _priceMaxDefault = 200;

  double _priceMin = _priceMinDefault;
  double _priceMax = _priceMaxDefault;

  // Filter options (cities, power output, amenities) fetched from the API.
  StationFilterOptionsEntity? _options;
  bool _optionsLoading = true;
  String? _optionsError;

  @override
  void initState() {
    super.initState();
    _initFromApplied();
    _loadOptions();
  }

  /// Pre-select whatever filters are currently applied on the map.
  void _initFromApplied() {
    final f = context.read<MapCubit>().currentFilters;
    _selectedAmenityIds.addAll(f.amenityIds);
    _selectedPowerOutput = f.powerOutput;
    _selectedCity = f.city;
    _availableNow = f.availableNow;
    _priceRange = RangeValues(
      (f.minPrice ?? _priceMin).clamp(_priceMin, _priceMax),
      (f.maxPrice ?? _priceMax).clamp(_priceMin, _priceMax),
    );
  }

  Future<void> _loadOptions() async {
    setState(() {
      _optionsLoading = true;
      _optionsError = null;
    });
    final result = await sl<GetFilterOptionsUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _optionsLoading = false;
        _optionsError = failure.message;
      }),
      (options) => setState(() {
        _optionsLoading = false;
        _options = options;
        // Drop any pre-selected ids/values that no longer exist in the options.
        final validIds = options.amenities.map((a) => a.id).toSet();
        _selectedAmenityIds.removeWhere((id) => !validIds.contains(id));
        if (_selectedPowerOutput != null &&
            !options.powerOutputOptions.contains(_selectedPowerOutput)) {
          _selectedPowerOutput = null;
        }
        if (_selectedCity != null && !options.cities.contains(_selectedCity)) {
          _selectedCity = null;
        }
        // Adopt the API's price bounds and re-fit the slider values.
        _applyPriceRange(options);
      }),
    );
  }

  /// Overwrites the price slider bounds with the API range (when valid) and
  /// re-clamps the current values: an applied filter is kept (clamped);
  /// otherwise price spans the full range.
  void _applyPriceRange(StationFilterOptionsEntity options) {
    final f = context.read<MapCubit>().currentFilters;

    final prMin = options.priceMin;
    final prMax = options.priceMax;
    if (prMin != null && prMax != null && prMax > prMin) {
      _priceMin = prMin;
      _priceMax = prMax;
    }
    _priceRange = RangeValues(
      (f.minPrice ?? _priceMin).clamp(_priceMin, _priceMax),
      (f.maxPrice ?? _priceMax).clamp(_priceMin, _priceMax),
    );
  }

  void _reset() {
    setState(() {
      _selectedCity = null;
      _selectedPowerOutput = null;
      _availableNow = false;
      _selectedAmenityIds.clear();
      _priceRange = RangeValues(_priceMin, _priceMax);
    });
  }

  void _apply() {
    final filters = StationFilters(
      amenityIds: _selectedAmenityIds.toList(growable: false),
      minPrice: _priceRange.start.roundToDouble(),
      maxPrice: _priceRange.end.roundToDouble(),
      powerOutput: _selectedPowerOutput,
      availableNow: _availableNow,
      city: _selectedCity,
    );
    context.read<MapCubit>().applyFilters(filters);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    // Fix the sheet at 70% of the screen height, but never let its top slide
    // under (or touch) the status bar — a small gap below it keeps it clear.
    // The inner SingleChildScrollView scrolls the content within this height.
    final maxSheetHeight =
        (media.size.height - media.padding.top - 8.h).clamp(0.0, double.infinity);
    final sheetHeight = (media.size.height * 0.7).clamp(0.0, maxSheetHeight);

    return Column(
      children: [
        // Empty space above the sheet: tapping it dismisses the sheet.
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        SizedBox(
          height: sheetHeight,
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
                            color: AppColors.removeColor,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.verticalSpace,
                  Divider(height: 1, thickness: 1, color: ui.borderSubtle),
                  18.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle('Location'),
                        10.verticalSpace,
                        _locationSection(ui),
                        20.verticalSpace,
                        _sectionTitle('Power Output'),
                        10.verticalSpace,
                        _powerOutputSection(ui),
                        20.verticalSpace,
                        // _sectionTitle('Availability'),
                        // 10.verticalSpace,
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: AppText(
                        //         'Available Now',
                        //         color: ui.textPrimary,
                        //         fontSize: FontSizes.font14Sp,
                        //         fontWeight: FontWeights.weight500,
                        //       ),
                        //     ),
                        //     _availabilitySwitch(),
                        //   ],
                        // ),
                        // 16.verticalSpace,
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
                        20.verticalSpace,
                        _sectionTitle('Amenities'),
                        8.verticalSpace,
                        _amenitiesSection(ui),
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
        ),
      ],
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

  // ── Location (dynamic, KLI cities only) ────────────────────────────────────

  Widget _locationSection(AppUiColors ui) {
    if (_optionsLoading) return _sectionLoader(ui);
    if (_optionsError != null && (_options?.cities.isEmpty ?? true)) {
      return _sectionError(ui);
    }
    final cities = _options?.cities ?? const [];
    if (cities.isEmpty) {
      return _sectionEmpty(ui, 'No locations available');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cities.map((city) {
          final selected = _selectedCity == city;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedCity = selected ? null : city;
              }),
              child: _optionChip(city, selected),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Power output (dynamic) ─────────────────────────────────────────────────

  Widget _powerOutputSection(AppUiColors ui) {
    if (_optionsLoading) return _sectionLoader(ui);
    if (_optionsError != null && (_options?.powerOutputOptions.isEmpty ?? true)) {
      return _sectionError(ui);
    }
    final powerOptions = _options?.powerOutputOptions ?? const [];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPowerOutput = null),
              child: _optionChip('All', _selectedPowerOutput == null),
            ),
          ),
          ...powerOptions.map((kw) {
            final selected = _selectedPowerOutput == kw;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedPowerOutput = selected ? null : kw;
                }),
                child: _optionChip('${kw.round()} kW', selected),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _optionChip(String label, bool selected) {
    final ui = AppUiColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: selected ? ui.brandPrimary : ui.borderSubtle,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: AppText(
        label,
        color: ui.textPrimary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }

  // ── Amenities (dynamic) ───────────────────────────────────────────────────

  Widget _amenitiesSection(AppUiColors ui) {
    if (_optionsLoading) return _sectionLoader(ui);
    if (_optionsError != null && (_options?.amenities.isEmpty ?? true)) {
      return _sectionError(ui);
    }
    final amenities = _options?.amenities ?? const [];
    if (amenities.isEmpty) {
      return _sectionEmpty(ui, 'No amenities available');
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6.h,
      crossAxisSpacing: 10.w,
      childAspectRatio: 4.5,
      children: amenities.map((amenity) {
        final on = _selectedAmenityIds.contains(amenity.id);
        return GestureDetector(
          onTap: () => setState(() {
            if (on) {
              _selectedAmenityIds.remove(amenity.id);
            } else {
              _selectedAmenityIds.add(amenity.id);
            }
          }),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              _amenityBox(on),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  amenity.name,
                  color: ui.textPrimary,
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: checked ? ui.brandPrimary : ui.borderSubtle,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: checked
          ? Icon(
              Icons.check,
              size: 12.r,
              color: ui.isLight ? AppColors.greyColor : AppColors.whiteColor,
            )
          : null,
    );
  }

  // ── Shared option-section states ──────────────────────────────────────────

  Widget _sectionLoader(AppUiColors ui) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: ui.brandPrimary,
          ),
        ),
      ),
    );
  }

  Widget _sectionError(AppUiColors ui) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            _optionsError ?? 'Could not load options.',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 2,
          ),
        ),
        8.horizontalSpace,
        GestureDetector(
          onTap: _loadOptions,
          behavior: HitTestBehavior.opaque,
          child: AppText(
            'Retry',
            color: ui.brandPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      ],
    );
  }

  Widget _sectionEmpty(AppUiColors ui, String label) {
    return AppText(
      label,
      color: ui.textMuted,
      fontSize: FontSizes.font12Sp,
      fontWeight: FontWeights.weight400,
    );
  }

  // ── Sliders & labels ──────────────────────────────────────────────────────

  Widget _priceLabelsRow() {
    final ui = AppUiColors.of(context);
    final left = _priceRange.start.round();
    final right = _priceRange.end.round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          'Rs $left per kWh',
          color: ui.textMuted,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        AppText(
          'Rs $right per kWh',
          color: ui.textMuted,
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
          enabledThumbRadius: 6.r,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
        trackHeight: 4.h,
        activeTrackColor: ui.brandPrimary,
        inactiveTrackColor: ui.progressTrack,
        thumbColor: ui.brandPrimary,
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
    return GradientSwitch(
      value: _availableNow,
      onChanged: (v) => setState(() => _availableNow = v),
    );
  }

  Widget _applyButton(BuildContext context) {
    return PrimaryButtonWidget(
      text: 'Apply Filters',
      onPress: _apply,
      buttonWidth: double.infinity,
      cornerRadius: 24.r,
      gradientColors: const [
        AppColors.primaryDarkColor,
        AppColors.primaryDarkButtonColor,
      ],
      textColor: AppColors.whiteColor,
      fontSize: FontSizes.font14Sp,
      fontWeight: FontWeights.weight700,
    );
  }
}

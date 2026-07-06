import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/presentation/home_screen.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_filters_bottom_sheet.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_unread_count_usecase.dart';

/// Shows the stations matching the filters applied from
/// [MapFiltersBottomSheet], laid out as a vertical list. It owns its own
/// [MapCubit] instance (provided by the route), so filtering here never touches
/// the home map or its "Nearby Stations" row.
class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key, required this.filters});

  final StationFilters filters;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  /// Nearby-stations chip filters (client-side refinement on top of the
  /// server-side filters already applied by [MapCubit]).
  bool _availableNowSelected = false;
  final Set<String> _selectedTypes = {};

  /// Unread notification count for the bell badge. 0 hides the badge.
  int _unreadCount = 0;

  /// Periodic poll for the unread count (no live push from the backend).
  Timer? _unreadPollTimer;
  static const Duration _unreadPollInterval = Duration(seconds: 45);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _unreadPollTimer = Timer.periodic(
      _unreadPollInterval,
      (_) => _refreshUnreadCount(),
    );
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    super.dispose();
  }

  /// Fetches the unread badge count. No-op for guests and silently ignores
  /// failures so the screen is never blocked.
  Future<void> _refreshUnreadCount() async {
    if (AppStorage.isGuest) {
      if (mounted && _unreadCount != 0) setState(() => _unreadCount = 0);
      return;
    }
    final result = await sl<GetUnreadCountUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (_) {},
      (count) {
        if (count != _unreadCount) setState(() => _unreadCount = count);
      },
    );
  }

  /// Opens the notifications list (guests are prompted to authenticate), then
  /// refreshes the badge on return.
  Future<void> _openNotifications() async {
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(
        context,
        message:
            'Please log in or create an account to view your notifications.',
      );
      return;
    }
    await context.push('/notifications');
    await _refreshUnreadCount();
  }

  /// Re-runs the current filters (used by the error-state retry action).
  void _retry() {
    context.read<MapCubit>().applyFilters(widget.filters);
  }

  /// Tapping a result closes this screen and asks the home map to zoom to the
  /// tapped station's charger marker (the home map data itself is untouched).
  void _focusOnHomeMap(HubcoLocationEntity station) {
    HomeScreen.focusStationNotifier.value = station;
    context.pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            10.verticalSpace,
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: _buildTopActions(context),
            ),
            12.verticalSpace,
            Expanded(child: _buildResultsSheet(context)),
          ],
        ),
      ),
    );
  }

  // ── Top actions (mirrors HomeScreen) ───────────────────────────────────────

  Widget _buildTopActions(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(10.r),
              child: Ink(
                padding: AppUtils.homeTopSearchPadding,
                decoration: BoxDecoration(
                  color: ui.searchBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: ui.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: ui.textMuted,
                      size: 25,
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: AppText(
                        'Search stations or locations',
                        color: ui.textMuted,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ),
                    8.horizontalSpace,
                    _topActionIcon(
                      context,
                      Icons.tune_rounded,
                      isPrimary: true,
                      isCompact: true,
                      onTap: () => MapFiltersBottomSheet.show(
                        context,
                        stationCount: _currentStationCount(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        _buildNotificationBell(context),
      ],
    );
  }

  int _currentStationCount() {
    final state = context.read<MapCubit>().state;
    return state is MapLoaded ? state.locations.length : 0;
  }

  /// Notification bell with an unread-count badge overlay.
  Widget _buildNotificationBell(BuildContext context) {
    final ui = AppUiColors.of(context);
    final bell = _topActionIcon(
      context,
      Icons.notifications_none_rounded,
      onTap: _openNotifications,
    );

    if (_unreadCount <= 0) return bell;

    final label = _unreadCount > 99 ? '99+' : '$_unreadCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bell,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            constraints: BoxConstraints(minWidth: 18.r),
            decoration: BoxDecoration(
              color: AppColors.removeColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: ui.scaffoldBackground, width: 1.5),
            ),
            alignment: Alignment.center,
            child: AppText(
              label,
              color: AppColors.whiteColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _topActionIcon(
    BuildContext context,
    IconData icon, {
    bool isPrimary = false,
    bool isCompact = false,
    VoidCallback? onTap,
  }) {
    final ui = AppUiColors.of(context);
    final radius = BorderRadius.circular(8.r);
    final child = Container(
      height: isCompact ? 34.h : 52.h,
      width: isCompact ? 34.w : 52.w,
      decoration: BoxDecoration(
        color: isPrimary ? ui.searchBackground : ui.searchBackground,
        borderRadius: radius,
        border: Border.all(
          color: isPrimary ? ui.brandPrimary : ui.borderSubtle,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: ui.textMuted,
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }

  // ── Results sheet (mirrors HomeScreen bottom sheet, vertical list) ──────────

  Widget _buildResultsSheet(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          final locations =
              state is MapLoaded ? state.locations : const <HubcoLocationEntity>[];
          final types = _distinctConnectorTypes(locations);
          // Ignore stale selections for types not present in the current data.
          final activeTypes = _selectedTypes.where(types.contains).toSet();
          final filtered = _applyChipFilters(locations, activeTypes);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  height: 3.h,
                  width: 66.w,
                  decoration: BoxDecoration(
                    color: ui.textSecondary.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              12.verticalSpace,
              AppText(
                'Results',
                color: ui.textPrimary,
                fontSize: FontSizes.font24Sp,
                fontWeight: FontWeights.weight600,
              ),
              10.verticalSpace,
              _buildFilterChips(context, types),
              12.verticalSpace,
              Expanded(
                child: _buildResultsBody(context, state, filtered, activeTypes),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsBody(
    BuildContext context,
    MapState state,
    List<HubcoLocationEntity> filtered,
    Set<String> activeTypes,
  ) {
    final ui = AppUiColors.of(context);

    if (state is MapLoading || state is MapInitial) {
      return Center(
        child: CircularProgressIndicator(color: ui.brandPrimary),
      );
    }

    if (state is MapError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              state.message,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight500,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            12.verticalSpace,
            GestureDetector(
              onTap: _retry,
              behavior: HitTestBehavior.opaque,
              child: AppText(
                'Retry',
                color: ui.brandPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      final hasActiveFilters =
          _availableNowSelected || activeTypes.isNotEmpty;
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: AppText(
            hasActiveFilters
                ? 'No stations match the selected filters'
                : 'No stations match your filters',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: 12.h),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => 10.verticalSpace,
      itemBuilder: (context, index) => _stationCard(context, filtered[index]),
    );
  }

  /// Distinct connector kinds (`type`) across all loaded stations, sorted.
  List<String> _distinctConnectorTypes(List<HubcoLocationEntity> stations) {
    final set = <String>{};
    for (final s in stations) {
      set.addAll(s.connectorTypes);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Applies the selected chips to [stations]: "Available Now" keeps only
  /// available stations; selected types keep stations matching any of them.
  List<HubcoLocationEntity> _applyChipFilters(
    List<HubcoLocationEntity> stations,
    Set<String> activeTypes,
  ) {
    return stations.where((s) {
      if (_availableNowSelected && !s.available) return false;
      if (activeTypes.isNotEmpty && !s.connectorTypes.any(activeTypes.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Horizontally-scrollable chip row: an "Available Now" toggle plus one chip
  /// per connector [types] value from the API.
  Widget _buildFilterChips(BuildContext context, List<String> types) {
    final chips = <Widget>[
      _chip(
        context,
        'Available Now',
        isActive: _availableNowSelected,
        onTap: () =>
            setState(() => _availableNowSelected = !_availableNowSelected),
      ),
      // for (final type in types)
      //   _chip(
      //     context,
      //     type,
      //     isActive: _selectedTypes.contains(type),
      //     onTap: () => setState(() {
      //       if (_selectedTypes.contains(type)) {
      //         _selectedTypes.remove(type);
      //       } else {
      //         _selectedTypes.add(type);
      //       }
      //     }),
      //   ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            chips[i],
          ],
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String text, {
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    final ui = AppUiColors.of(context);
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: AppUtils.homeFilterChipPadding,
      decoration: BoxDecoration(
        color:
            isActive ? ui.brandPrimary.withValues(alpha: 0.12) : ui.innerCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? ui.brandPrimary : ui.borderSubtle,
        ),
      ),
      child: AppText(
        text,
        color: ui.textPrimary.withValues(alpha: 0.8),
        fontSize: FontSizes.font14Sp,
        fontWeight: isActive ? FontWeights.weight600 : FontWeights.weight400,
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }

  // ── Station card (mirrors HomeScreen) ───────────────────────────────────────

  String _stationDistanceLabel(HubcoLocationEntity station) {
    return AppHelpers.formatDistanceKm(station.distance);
  }

  /// Card title from the API `area`/`city`, e.g. `HGL – F11, Islamabad`.
  /// Empty when neither is provided (the card then falls back to the name).
  String _stationLocationLabel(HubcoLocationEntity station) {
    final parts = [station.area, station.city].where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '';
    return 'HGL – ${parts.join(', ')}';
  }

  String _stationAvailabilityLabel(HubcoLocationEntity station) {
    final total = station.numberOfConnectors;
    if (total <= 0) return '—';
    return '${station.availableConnectors}/$total Available';
  }

  /// Peak power(s) formatted like `60 kW` (joins multiple with `/`). Empty when
  /// the API sent no `power` values.
  String _stationPowerLabel(HubcoLocationEntity station) {
    if (station.powerOutputs.isEmpty) return '';
    final parts = station.powerOutputs.map((p) =>
        p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1));
    return '${parts.join('/')} kW';
  }

  String _stationPriceLabel(HubcoLocationEntity station) {
    if (station.prices.isEmpty) return '—';

    final price = station.prices.first;
    final amount = price.price == price.price.roundToDouble()
        ? price.price.toStringAsFixed(0)
        : price.price.toStringAsFixed(2);
    final currency = price.currency.trim();
    final mode = price.pricingMode.trim().toLowerCase();

    final buffer = StringBuffer();
    if (currency.isNotEmpty) {
      buffer.write(currency == 'PKR' ? 'Rs' : currency);
      buffer.write(' ');
    }
    buffer.write(amount);
    if (mode == 'kwh') {
      buffer.write('/kWh');
    } else if (mode.isNotEmpty) {
      buffer.write('/');
      buffer.write(mode.replaceAll('_', ' '));
    }
    return buffer.toString();
  }

  Widget _stationCard(BuildContext context, HubcoLocationEntity station) {
    final ui = AppUiColors.of(context);
    final locationLabel = _stationLocationLabel(station);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => _focusOnHomeMap(station),
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
          decoration: BoxDecoration(
            color: ui.innerCardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: ui.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      locationLabel.isNotEmpty ? locationLabel : station.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  8.horizontalSpace,
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: ui.textPrimary,
                          size: 10.sp,
                        ),
                        4.horizontalSpace,
                        AppText(
                          _stationDistanceLabel(station),
                          color: ui.textPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (locationLabel.isNotEmpty) ...[
                2.verticalSpace,
                AppText(
                  station.name,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              4.verticalSpace,
              AppText(
                _stationAvailabilityLabel(station),
                color: ui.textSecondary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight500,
              ),
              8.verticalSpace,
              Row(
                children: [
                  _StationPlugIconsRow(
                    color: ui.textSecondary,
                    powerLabel: _stationPowerLabel(station),
                  ),
                  const Spacer(),
                  Flexible(
                    child: AppText(
                      _stationPriceLabel(station),
                      color: ui.textSecondary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  16.horizontalSpace,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationPlugIconsRow extends StatelessWidget {
  const _StationPlugIconsRow({required this.color, this.powerLabel = ''});

  final Color color;

  /// Peak power label (e.g. `60 kW`) shown next to the plug icon; hidden empty.
  final String powerLabel;

  static const _iconSize = 34.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PlugIcon(assetPath: AppImages.icCss2, color: color),
        if (powerLabel.isNotEmpty) ...[
          8.horizontalSpace,
          AppText(
            powerLabel,
            color: color,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
        50.horizontalSpace,
      ],
    );
  }
}

class _PlugIcon extends StatelessWidget {
  const _PlugIcon({
    required this.assetPath,
    required this.color,
  });

  final String assetPath;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = _StationPlugIconsRow._iconSize.sp;

    if (assetPath.endsWith('.svg')) {
      return AppSvgImageView(
        appImagePath: assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: color,
      );
    }

    return AppPngImageView(
      appImagePath: assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

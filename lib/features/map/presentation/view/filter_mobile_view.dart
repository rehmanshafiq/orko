import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/view/home_mobile_view.dart';
import 'package:orko_hubco/features/map/presentation/widgets/filter_results_sheet_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_top_actions_widget.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_unread_count_usecase.dart';

/// Mobile layout for the filter results screen: a top action bar plus the
/// vertical results sheet. Owns the client-side chip selection and the
/// notification-badge polling; the [MapCubit] is provided by the route.
class FilterMobileView extends StatefulWidget {
  const FilterMobileView({super.key, required this.filters});

  final StationFilters filters;

  @override
  State<FilterMobileView> createState() => _FilterMobileViewState();
}

class _FilterMobileViewState extends State<FilterMobileView> {
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
    HomeMobileView.focusStationNotifier.value = station;
    context.pop();
  }

  int _currentStationCount() {
    final state = context.read<MapCubit>().state;
    return state is MapLoaded ? state.locations.length : 0;
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
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
              child: MapTopActionsWidget(
                stationCount: _currentStationCount(),
                unreadCount: _unreadCount,
                onNotificationsTap: _openNotifications,
                compactFilterSize: 34,
              ),
            ),
            12.verticalSpace,
            Expanded(
              child: FilterResultsSheetWidget(
                availableNowSelected: _availableNowSelected,
                selectedTypes: _selectedTypes,
                onToggleAvailableNow: () => setState(
                  () => _availableNowSelected = !_availableNowSelected,
                ),
                onToggleType: _toggleType,
                onRetry: _retry,
                onStationTap: _focusOnHomeMap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_user_vehicles_usecase.dart';

/// Loads the logged-in user's vehicles (`user-vehicle`) and shows them in a
/// dropdown for the trip planner. Self-contained: handles guest, loading,
/// error (+retry), empty, and success states.
class TripVehicleDropdownWidget extends StatefulWidget {
  const TripVehicleDropdownWidget({super.key, this.onVehicleSelected});

  /// Notified whenever the selection changes (null when cleared/none).
  final ValueChanged<UserVehicleEntity?>? onVehicleSelected;

  /// Clears the session-scoped last selection so a fresh instance starts empty
  /// (used by the trip planner's "Clear" action).
  static void clearSavedSelection() {
    _TripVehicleDropdownWidgetState._lastSelection = null;
  }

  @override
  State<TripVehicleDropdownWidget> createState() =>
      _TripVehicleDropdownWidgetState();
}

enum _Status { idle, loading, failure, success }

class _TripVehicleDropdownWidgetState extends State<TripVehicleDropdownWidget> {
  // The Trip tab is rebuilt from scratch on every tab tap (fresh bloc + state),
  // so the last selected make is held here, session-scoped, to survive that
  // rebuild. It is restored on init and refreshed when the field is tapped.
  static UserVehicleEntity? _lastSelection;

  // Vehicles are fetched lazily — the API call fires when the user taps the
  // Make field, not when the Trip tab first builds.
  _Status _status = _Status.idle;
  String? _error;
  List<UserVehicleEntity> _vehicles = const [];
  int? _selectedId;

  // Drives the custom dropdown so we can open the menu first and then refresh
  // its contents live (the native DropdownButton can't update while open).
  final MenuController _menuController = MenuController();

  bool get _isGuest => AppStorage.isGuest;

  @override
  void initState() {
    super.initState();
    // Restore the previously selected make (without an API call) so switching
    // tabs and returning keeps the selection. Tapping the field reloads it.
    if (!_isGuest && _lastSelection != null) {
      _selectedId = _lastSelection!.id;
      _vehicles = [_lastSelection!];
      // Re-notify the (fresh) bloc so EV details reflect the restored vehicle.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onVehicleSelected?.call(_selected);
      });
    }
  }

  /// Fetches the user's vehicles. When [silent] is true the existing options
  /// stay visible while refreshing (used when reopening the dropdown), so the
  /// open menu isn't torn down by flipping to the loading state.
  Future<void> _load({bool silent = false}) async {
    if (_isGuest) return;
    if (!silent) {
      setState(() {
        _status = _Status.loading;
        _error = null;
      });
    }
    final result = await sl<GetUserVehiclesUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) {
        // On a background refresh, keep showing what we already have.
        if (silent && _vehicles.isNotEmpty) return;
        setState(() {
          _status = _Status.failure;
          _error = failure.message;
        });
      },
      (vehicles) {
        setState(() {
          _status = _Status.success;
          _vehicles = vehicles;
          // Keep a valid selection; default to the first vehicle that can be
          // planned (complete battery/range data).
          final stillValid = _selectedId != null &&
              vehicles.any((v) => v.id == _selectedId && _isComplete(v));
          if (!stillValid) {
            _selectedId = _firstComplete(vehicles)?.id;
          }
        });
        _lastSelection = _selected;
        widget.onVehicleSelected?.call(_selected);
      },
    );
  }

  /// A vehicle can only be planned with complete battery + range data. Mirrors
  /// the API's "range_km == 0 / battery_capacity == null → can't be planned".
  bool _isComplete(UserVehicleEntity v) =>
      v.range != null && v.range != 0 && v.batteryCapacity != null;

  UserVehicleEntity? _firstComplete(List<UserVehicleEntity> vehicles) {
    for (final v in vehicles) {
      if (_isComplete(v)) return v;
    }
    return null;
  }

  UserVehicleEntity? get _selected {
    for (final v in _vehicles) {
      if (v.id == _selectedId) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Select Vehicle',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        _buildField(ui),
      ],
    );
  }

  Widget _buildField(AppUiColors ui) {
    if (_isGuest) {
      return _shell(
        ui,
        child: AppText(
          'Sign in to select your vehicle',
          color: AppColors.hintColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      );
    }

    final selected = _selected;
    final isLoading = _status == _Status.loading;
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;
        return MenuAnchor(
          controller: _menuController,
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(ui.cardBackground),
            padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4.h)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          menuChildren: _menuItems(ui, menuWidth),
          builder: (context, controller, _) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                  return;
                }
                // Open the menu first, then fetch — the open menu updates live
                // as the result arrives. Keep existing options visible while
                // refreshing so they don't flash away.
                controller.open();
                _load(silent: _vehicles.isNotEmpty);
              },
              child: _shell(
                ui,
                trailing: isLoading
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ui.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ui.textSecondary,
                        size: 20.r,
                      ),
                child: AppText(
                  selected != null ? _label(selected) : 'Select Vehicle',
                  color:
                      selected != null ? ui.textPrimary : AppColors.hintColor,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: selected != null
                      ? FontWeights.weight500
                      : FontWeights.weight400,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the open menu's contents from the current status — a loading row,
  /// a retry row, an empty hint, or the vehicle options.
  List<Widget> _menuItems(AppUiColors ui, double width) {
    if (_status == _Status.loading && _vehicles.isEmpty) {
      return [_menuMessage(ui, width, 'Loading vehicles...')];
    }
    if (_status == _Status.failure && _vehicles.isEmpty) {
      return [
        MenuItemButton(
          onPressed: () {
            _menuController.close();
            _load();
          },
          child: SizedBox(
            width: width,
            child: AppText(
              '${_error ?? 'Could not load your vehicles.'} · Retry',
              color: AppColors.redColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
              maxLines: 2,
            ),
          ),
        ),
      ];
    }
    if (_vehicles.isEmpty) {
      return [_menuMessage(ui, width, 'No vehicles — add one in your profile')];
    }
    return [
      for (final v in _vehicles)
        MenuItemButton(
          onPressed: _isComplete(v)
              ? () {
                  setState(() => _selectedId = v.id);
                  _lastSelection = _selected;
                  widget.onVehicleSelected?.call(_selected);
                }
              : null,
          child: SizedBox(
            width: width,
            child: AppText(
              _isComplete(v) ? _label(v) : '${_label(v)} · incomplete data',
              color: _isComplete(v) ? ui.textPrimary : AppColors.hintColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
    ];
  }

  Widget _menuMessage(AppUiColors ui, double width, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: SizedBox(
        width: width - 24.w,
        child: AppText(
          message,
          color: AppColors.hintColor,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
      ),
    );
  }

  /// Item label — make first (per the "Make" dropdown), with model/connector
  /// appended for clarity when present.
  String _label(UserVehicleEntity v) {
    final make = v.makeName.trim();
    final model = v.modelName.trim();
    final base = [make, model].where((p) => p.isNotEmpty).join(' ');
    final name = base.isEmpty ? v.displayName : base;
    final connector = v.connectorType.trim();
    return connector.isEmpty ? name : '$name · $connector';
  }

  /// The location-field-styled container the dropdown/messages sit inside.
  Widget _shell(
    AppUiColors ui, {
    required Widget child,
    Widget? trailing,
    Color? borderColor,
  }) {
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor ?? ui.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car_rounded,
            size: 14.sp,
            color: ui.brandPrimary,
          ),
          8.horizontalSpace,
          Expanded(child: child),
          if (trailing != null) ...[
            8.horizontalSpace,
            trailing,
          ],
        ],
      ),
    );
  }
}

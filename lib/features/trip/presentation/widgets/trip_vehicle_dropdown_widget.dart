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

  @override
  State<TripVehicleDropdownWidget> createState() =>
      _TripVehicleDropdownWidgetState();
}

enum _Status { loading, failure, success }

class _TripVehicleDropdownWidgetState extends State<TripVehicleDropdownWidget> {
  _Status _status = _Status.loading;
  String? _error;
  List<UserVehicleEntity> _vehicles = const [];
  int? _selectedId;

  bool get _isGuest => AppStorage.isGuest;

  @override
  void initState() {
    super.initState();
    if (!_isGuest) _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
    });
    final result = await sl<GetUserVehiclesUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _status = _Status.failure;
        _error = failure.message;
      }),
      (vehicles) => setState(() {
        _status = _Status.success;
        _vehicles = vehicles;
        // Keep a valid selection; default to the first vehicle that can be
        // planned (complete battery/range data).
        final stillValid = _selectedId != null &&
            vehicles.any((v) => v.id == _selectedId && _isComplete(v));
        if (!stillValid) {
          _selectedId = _firstComplete(vehicles)?.id;
        }
        widget.onVehicleSelected?.call(_selected);
      }),
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
          'Make',
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

    switch (_status) {
      case _Status.loading:
        return _shell(
          ui,
          trailing: SizedBox(
            width: 16.r,
            height: 16.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ui.textSecondary,
            ),
          ),
          child: AppText(
            'Loading vehicles...',
            color: AppColors.hintColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        );
      case _Status.failure:
        return _shell(
          ui,
          borderColor: AppColors.redColor,
          trailing: GestureDetector(
            onTap: _load,
            behavior: HitTestBehavior.opaque,
            child: AppText(
              'Retry',
              color: ui.brandPrimary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
          child: AppText(
            _error ?? 'Could not load your vehicles.',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      case _Status.success:
        if (_vehicles.isEmpty) {
          return _shell(
            ui,
            child: AppText(
              'No vehicles — add one in your profile',
              color: AppColors.hintColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          );
        }
        return _shell(
          ui,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedId,
              isExpanded: true,
              isDense: true,
              dropdownColor: ui.cardBackground,
              borderRadius: BorderRadius.circular(8.r),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ui.textSecondary,
                size: 20.r,
              ),
              style: TextStyle(
                color: ui.textPrimary.withValues(alpha: 0.9),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
              items: [
                for (final v in _vehicles)
                  DropdownMenuItem<int>(
                    value: v.id,
                    enabled: _isComplete(v),
                    child: AppText(
                      _isComplete(v)
                          ? _label(v)
                          : '${_label(v)} · incomplete data',
                      color: _isComplete(v)
                          ? ui.textPrimary
                          : AppColors.hintColor,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (id) {
                setState(() => _selectedId = id);
                widget.onVehicleSelected?.call(_selected);
              },
            ),
          ),
        );
    }
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

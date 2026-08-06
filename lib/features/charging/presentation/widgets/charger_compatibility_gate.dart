import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/presentation/pages/book_slot_page.dart';
import 'package:orko_hubco/features/charging/domain/entities/charger_compatibility_entity.dart';
import 'package:orko_hubco/features/charging/domain/usecases/check_charger_compatibility_usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_user_vehicles_usecase.dart';

/// Orchestrates the "Book Slot" pre-flight: resolve the user's vehicle, check it
/// against the charger, and only navigate to booking when compatible.
///
/// Flow:
/// 1. Fetch the user's vehicles. None → prompt to add one.
/// 2. One vehicle → use it; many → let the user pick.
/// 3. No `charge_point_id` available → proceed (fail-open) so a missing backend
///    field never blocks an otherwise-valid booking.
/// 4. Run the compatibility check. Compatible → navigate; incompatible → show
///    the mismatch and STOP (hard block); error → surface the message and STOP.
class ChargerCompatibilityGate {
  const ChargerCompatibilityGate._();

  static Future<void> run(
    BuildContext context, {
    required HubcoLocationEntity station,
    required String? chargePointId,
    String openingTime = '',
    String closingTime = '',
  }) async {
    // 1. Fetch the user's vehicles.
    _showLoader(context);
    final vehiclesResult = await sl<GetUserVehiclesUseCase>().call(
      const NoParams(),
    );
    if (!context.mounted) return;
    _dismissLoader(context);

    if (vehiclesResult.isLeft) {
      _logCompatibilityCheck(station.id, 'error');
      _showMessageDialog(
        context,
        icon: Icons.error_outline_rounded,
        title: 'Something went wrong',
        message: vehiclesResult.fold((f) => f.message, (_) => ''),
      );
      return;
    }

    final vehicles = vehiclesResult.getOrElse(() => const []);
    if (vehicles.isEmpty) {
      _logCompatibilityCheck(station.id, 'no_vehicle');
      _showNoVehiclesDialog(context);
      return;
    }

    // 2. Resolve which vehicle to check.
    final vehicle = vehicles.length == 1
        ? vehicles.first
        : await _pickVehicle(context, vehicles);
    if (vehicle == null || !context.mounted) return;

    // 3. No charge point id → can't verify; don't block a valid booking.
    final cpId = chargePointId?.trim();
    if (cpId == null || cpId.isEmpty) {
      _logCompatibilityCheck(station.id, 'no_charge_point');
      _proceedToBooking(
        context,
        station,
        vehicle.id,
        openingTime: openingTime,
        closingTime: closingTime,
      );
      return;
    }

    // 4. Check compatibility.
    _showLoader(context);
    final compatResult = await sl<CheckChargerCompatibilityUseCase>().call(
      CheckChargerCompatibilityParams(
        csmsVehicleId: vehicle.id,
        chargePointId: cpId,
      ),
    );
    if (!context.mounted) return;
    _dismissLoader(context);

    compatResult.fold(
      (failure) {
        _logCompatibilityCheck(station.id, 'error');
        _showMessageDialog(
          context,
          icon: Icons.error_outline_rounded,
          title: 'Compatibility check failed',
          message: failure.message,
        );
      },
      (compat) {
        if (compat.isCompatible) {
          _logCompatibilityCheck(station.id, 'compatible');
          _proceedToBooking(
            context,
            station,
            vehicle.id,
            openingTime: openingTime,
            closingTime: closingTime,
          );
        } else {
          _logCompatibilityCheck(station.id, 'incompatible');
          _showIncompatibleDialog(context, vehicle, compat);
        }
      },
    );
  }

  /// Logs the `compatibility_check` gate result on every terminal branch so the
  /// event fires whenever the gate runs. [result] is one of:
  /// - `compatible` / `incompatible` — an actual vehicle↔charger check ran;
  /// - `no_vehicle` — the user has no vehicle to check;
  /// - `no_charge_point` — the station exposes no charge-point id, so the gate
  ///   fails open to booking without a check (kept distinct so it never inflates
  ///   the `compatible` rate);
  /// - `error` — fetching vehicles or the compatibility check itself failed.
  static void _logCompatibilityCheck(int stationId, String result) {
    sl<AnalyticsService>().logEvent('compatibility_check', parameters: {
      'result': result,
      'station_id': stationId,
    });
  }

  static void _proceedToBooking(
    BuildContext context,
    HubcoLocationEntity station,
    int vehicleId, {
    String openingTime = '',
    String closingTime = '',
  }) {
    context.push(
      '/book-slot',
      extra: BookSlotArgs(
        station: station,
        vehicleId: vehicleId,
        openingTime: openingTime,
        closingTime: closingTime,
      ),
    );
  }

  // ── Loader ──────────────────────────────────────────────────────────────

  static void _showLoader(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: AppColors.blackColor.withValues(alpha: 0.45),
        builder: (_) => Center(
          child: SizedBox(
            width: 36.w,
            height: 36.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: AppUiColors.of(context).brandPrimary,
            ),
          ),
        ),
      ),
    );
  }

  static void _dismissLoader(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Vehicle picker ────────────────────────────────────────────────────────

  static Future<UserVehicleEntity?> _pickVehicle(
    BuildContext context,
    List<UserVehicleEntity> vehicles,
  ) {
    final ui = AppUiColors.of(context);
    return showModalBottomSheet<UserVehicleEntity>(
      context: context,
      backgroundColor: ui.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                'Select a vehicle',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
              6.verticalSpace,
              AppText(
                'Choose which vehicle to check against this charger.',
                color: ui.textSecondary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
              14.verticalSpace,
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => 10.verticalSpace,
                  itemBuilder: (_, index) {
                    final v = vehicles[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () => Navigator.of(sheetContext).pop(v),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: ui.inputFill,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: ui.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.electric_car_rounded,
                                color: ui.brandPrimary, size: 22.r),
                            12.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    v.displayName,
                                    color: ui.textPrimary,
                                    fontSize: FontSizes.font14Sp,
                                    fontWeight: FontWeights.weight600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (v.connectorType.isNotEmpty) ...[
                                    2.verticalSpace,
                                    AppText(
                                      v.connectorType,
                                      color: ui.textSecondary,
                                      fontSize: FontSizes.font12Sp,
                                      fontWeight: FontWeights.weight400,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: ui.textSecondary, size: 22.r),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Result dialogs ──────────────────────────────────────────────────────

  static void _showNoVehiclesDialog(BuildContext context) {
    final ui = AppUiColors.of(context);
    showDialog<void>(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
      builder: (dialogContext) => _GateDialog(
        ui: ui,
        icon: Icons.directions_car_outlined,
        iconColor: ui.brandPrimary,
        title: 'No vehicle found',
        message:
            'Add a vehicle to your profile before booking, so we can check it '
            'is compatible with this charger.',
        primaryLabel: 'Add Vehicle',
        onPrimary: () {
          Navigator.of(dialogContext).pop();
          context.go('/account');
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  static void _showMessageDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final ui = AppUiColors.of(context);
    showDialog<void>(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
      builder: (dialogContext) => _GateDialog(
        ui: ui,
        icon: icon,
        iconColor: AppColors.removeColor,
        title: title,
        message: message.isNotEmpty ? message : 'Please try again.',
        primaryLabel: 'OK',
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  static void _showIncompatibleDialog(
    BuildContext context,
    UserVehicleEntity vehicle,
    ChargerCompatibilityEntity compat,
  ) {
    final ui = AppUiColors.of(context);
    final vehicleConnector = (compat.vehicle?.connectorType.isNotEmpty ?? false)
        ? compat.vehicle!.connectorType
        : vehicle.connectorType;
    final incompatibleTypes = compat.incompatibleConnectors
        .map((c) => c.connectorType)
        .where((t) => t.isNotEmpty)
        .toSet()
        .join(', ');

    showDialog<void>(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
      builder: (dialogContext) => _GateDialog(
        ui: ui,
        icon: Icons.ev_station_outlined,
        iconColor: AppColors.removeColor,
        title: 'Charger not compatible',
        message: [
          '${vehicle.displayName} uses '
              '${vehicleConnector.isNotEmpty ? vehicleConnector : 'an unsupported'} connector, '
              'which this charger does not support.',
          if (incompatibleTypes.isNotEmpty)
            'This charger offers: $incompatibleTypes.',
          'Booking is not available for this vehicle here.',
        ].join('\n\n'),
        primaryLabel: 'OK',
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}

class _GateDialog extends StatelessWidget {
  const _GateDialog({
    required this.ui,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final AppUiColors ui;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ui.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: AppUtils.all18Padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22.r),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    title,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font18Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            AppText(
              message,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
              height: 1.4,
            ),
            22.verticalSpace,
            Row(
              children: [
                if (secondaryLabel != null) ...[
                  Expanded(
                    child: PrimaryButtonWidget(
                      text: secondaryLabel!,
                      onPress: onSecondary ?? () {},
                      buttonWidth: double.infinity,
                      buttonHeight: 42.h,
                      cornerRadius: 12.r,
                      buttonColor: ui.chipInactiveBg,
                      strokeColor: ui.borderSubtle,
                      textColor: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ),
                  12.horizontalSpace,
                ],
                Expanded(
                  child: PrimaryButtonWidget(
                    text: primaryLabel,
                    onPress: onPrimary,
                    buttonWidth: double.infinity,
                    buttonHeight: 42.h,
                    cornerRadius: 12.r,
                    gradientColors: const [
                      AppColors.primaryDarkColor,
                      AppColors.primaryDarkButtonColor,
                    ],
                    textColor: AppColors.whiteColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

/// Trims a trailing `.0` (40.0 → "40", 40.8 → "40.8").
String _trimNum(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onDelete,
    this.isDeleting = false,
  });

  final UserVehicleEntity vehicle;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final capacity = vehicle.batteryCapacity != null
        ? '${_trimNum(vehicle.batteryCapacity!)} kWh'
        : '—';
    final range =
        vehicle.range != null ? '${_trimNum(vehicle.range!)} km' : '—';
    final energy = '${_trimNum(vehicle.totalEnergyCharged)} kWh';

    return Container(
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.brandPrimary.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VehicleImage(imageUrl: vehicle.modelImage),
          Padding(
            padding: AppUtils.all12Padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            vehicle.displayName,
                            color: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (vehicle.registrationNo != null &&
                              vehicle.registrationNo!.trim().isNotEmpty) ...[
                            6.verticalSpace,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 14.r,
                                  color: ui.textSecondary,
                                ),
                                4.horizontalSpace,
                                Flexible(
                                  child: AppText(
                                    vehicle.registrationNo!.trim(),
                                    color: ui.textPrimary,
                                    fontSize: FontSizes.font12Sp,
                                    fontWeight: FontWeights.weight600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDeleting)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.removeColor,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32.r,
                          minHeight: 32.r,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.removeColor,
                          size: 22.r,
                        ),
                      ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: VehicleStatBox(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'Capacity',
                        value: capacity,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: VehicleStatBox(
                        icon: Icons.route_outlined,
                        label: 'Range',
                        value: range,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: VehicleStatBox(
                        icon: Icons.bolt_rounded,
                        label: 'Charges',
                        value: vehicle.totalCharges.toString(),
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Total Energy Charged',
                        color: ui.textSecondary,
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ),
                    AppText(
                      energy,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vehicle photo banner. Falls back to a placeholder when there is no image
/// or it fails to load.
class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _VehicleImagePlaceholder(ui: ui);
    }
    // CachedNetworkImage keeps the decoded image in memory + on disk, so once a
    // vehicle's photo has loaded it re-appears instantly — no spinner flash when
    // the list rebuilds (e.g. right after adding a vehicle) or when scrolling
    // between cards. Decoding to the on-screen height keeps memory low and the
    // decode fast.
    final cacheHeight =
        (140.h * MediaQuery.of(context).devicePixelRatio).round();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheKey: imageUrl,
      height: 140.h,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheHeight: cacheHeight,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => Container(
        height: 140.h,
        width: double.infinity,
        color: ui.vehicleImagePlaceholder,
        alignment: Alignment.center,
        child: SizedBox(
          width: 24.r,
          height: 24.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: ui.brandPrimary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _VehicleImagePlaceholder(ui: ui),
    );
  }
}

class _VehicleImagePlaceholder extends StatelessWidget {
  const _VehicleImagePlaceholder({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140.h,
      width: double.infinity,
      color: ui.vehicleImagePlaceholder,
      alignment: Alignment.center,
      child: Icon(
        Icons.electric_car_rounded,
        size: 72.r,
        color: ui.brandPrimary.withValues(alpha: 0.85),
      ),
    );
  }
}

class VehicleStatBox extends StatelessWidget {
  const VehicleStatBox({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: ui.textSecondary, size: 18.r),
          6.verticalSpace,
          AppText(
            label,
            color: ui.textSecondary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          4.verticalSpace,
          AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight700,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

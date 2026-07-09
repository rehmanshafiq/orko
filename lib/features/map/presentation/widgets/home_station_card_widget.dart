import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Station summary card used in the home bottom sheet. [isHorizontal] renders
/// the compact fixed-width variant used in the collapsed horizontal list.
class HomeStationCardWidget extends StatelessWidget {
  const HomeStationCardWidget(
    this.station, {
    super.key,
    this.isHorizontal = false,
  });

  final HubcoLocationEntity station;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final locationLabel = _locationLabel(station);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: () => context.push('/station-detail', extra: station),
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
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
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
                          AppHelpers.formatDistanceKm(station.distance),
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
                5.verticalSpace,
                AppText(
                  station.name,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: FontWeights.weight500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              6.verticalSpace,
              AppText(
                _availabilityLabel(station),
                color: ui.textSecondary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight500,
              ),
              8.verticalSpace,
              Row(
                children: [
                  _StationPlugIconsRow(
                    color: ui.textSecondary,
                    powerLabel: _powerLabel(station),
                  ),
                  if (isHorizontal) 14.horizontalSpace else const Spacer(),
                  Flexible(
                    child: AppText(
                      _priceLabel(station),
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

/// Card title from the API `area`/`city`, e.g. `HGL – F11, Islamabad`.
/// Empty when neither is provided (the card then falls back to the name).
String _locationLabel(HubcoLocationEntity station) {
  final parts = [station.area, station.city].where((s) => s.isNotEmpty);
  if (parts.isEmpty) return '';
  return 'HGL – ${parts.join(', ')}';
}

String _availabilityLabel(HubcoLocationEntity station) {
  final total = station.numberOfConnectors;
  if (total <= 0) return '—';
  return '${station.availableConnectors}/$total Available';
}

/// Peak power(s) formatted like `60 kW` (joins multiple with `/`). Empty when
/// the API sent no `power` values.
String _powerLabel(HubcoLocationEntity station) {
  if (station.powerOutputs.isEmpty) return '';
  final parts = station.powerOutputs.map((p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1));
  return '${parts.join('/')} kW';
}

String _priceLabel(HubcoLocationEntity station) {
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
        // _PlugIcon(assetPath: AppImages.icCcs, color: color),
        // 2.horizontalSpace,
        // _PlugIcon(assetPath: AppImages.icCcs1, color: color),
        // 2.horizontalSpace,
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
  const _PlugIcon({required this.assetPath, required this.color});

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

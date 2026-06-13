import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_port_icon_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_port_status_chip_widget.dart';

class ChargingStationPortItemWidget extends StatelessWidget {
  const ChargingStationPortItemWidget({
    super.key,
    required this.port,
    required this.isSelected,
    required this.onTap,
    required this.iconSize,
    required this.iconGap,
  });

  final ChargerPortModel port;
  final bool isSelected;
  final VoidCallback? onTap;
  final double iconSize;
  final double iconGap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        splashColor: ui.textPrimary.withValues(alpha: 0.06),
        highlightColor: ui.textPrimary.withValues(alpha: 0.04),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: isSelected ? ui.innerRowBg : AppColors.transparentColor,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ChargingStationPortIconWidget(
                diameter: iconSize,
              ),
                8.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: AppText(
                              port.label,
                              color: ui.textPrimary,
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          6.verticalSpace,
                          AppText(
                            port.price,
                            color: ui.textSecondary,
                            fontSize: FontSizes.font11Sp,
                            fontWeight: FontWeights.weight400,
                          ),
                          8.horizontalSpace,
                          ChargingStationPortStatusChipWidget(
                            available: port.available,
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

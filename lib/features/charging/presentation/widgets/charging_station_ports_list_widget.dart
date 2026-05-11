import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_port_item_widget.dart';

/// Charger Ports: flat list, selection highlight, divider inset past icon.
class ChargingStationPortsListWidget extends StatelessWidget {
  const ChargingStationPortsListWidget({
    super.key,
    required this.ports,
    required this.selectedPortIndex,
    required this.onAvailablePortTap,
  });

  final List<ChargerPortModel> ports;
  final int selectedPortIndex;
  final void Function(int index) onAvailablePortTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final iconSize = 44.r;
    final iconGap = 12.w;
    final dividerLeft = iconSize + iconGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ports.length; i++) ...[
          ChargingStationPortItemWidget(
            port: ports[i],
            canSelect: ports[i].available,
            isSelected: ports[i].available && i == selectedPortIndex,
            onTap: ports[i].available ? () => onAvailablePortTap(i) : null,
            iconSize: iconSize,
            iconGap: iconGap,
          ),
          if (i < ports.length - 1)
            Padding(
              padding: EdgeInsets.only(left: dividerLeft),
              child: Divider(
                height: 1,
                thickness: 1,
                color: ui.borderSubtle,
              ),
            ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_port_item_widget.dart';

/// Charger Ports: flat, non-interactive list without separators.
class ChargingStationPortsListWidget extends StatelessWidget {
  const ChargingStationPortsListWidget({
    super.key,
    required this.ports,
  });

  final List<ChargerPortModel> ports;

  @override
  Widget build(BuildContext context) {
    final iconSize = 44.r;
    final iconGap = 12.w;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final port in ports)
          ChargingStationPortItemWidget(
            port: port,
            iconSize: iconSize,
            iconGap: iconGap,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/port_card.dart';

/// Horizontal list of the location's connectors. The first available connector
/// is preselected by the cubit; the cards are display-only. Unavailable
/// connectors (Preparing/Faulted/etc.) are dimmed.
class ChargerPortSelector extends StatelessWidget {
  const ChargerPortSelector({
    super.key,
    required this.ui,
    required this.ports,
    required this.selectedPortId,
  });

  final AppUiColors ui;
  final List<ChargerPortEntity> ports;
  final int? selectedPortId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ports.length,
        separatorBuilder: (_, __) => 10.horizontalSpace,
        itemBuilder: (context, index) {
          final port = ports[index];
          return PortCard(
            ui: ui,
            portLabel: 'Port ${index + 1}',
            specs: port.connectorType.isEmpty ? '—' : port.connectorType,
            stateLabel: port.connectorState.isEmpty
                ? 'Unknown'
                : port.connectorState,
            enabled: port.isAvailable,
            selected: port.id == selectedPortId,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/port_card.dart';

class ChargerPortSelector extends StatelessWidget {
  const ChargerPortSelector({
    super.key,
    required this.ui,
    required this.selectedPortIndex,
    required this.onPortSelected,
  });

  final AppUiColors ui;
  final int selectedPortIndex;
  final ValueChanged<int> onPortSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          PortCard(
            ui: ui,
            portLabel: 'Port 1',
            specs: 'CCS,\n350kW',
            selected: selectedPortIndex == 0,
            onTap: () => onPortSelected(0),
          ),
          10.horizontalSpace,
          PortCard(
            ui: ui,
            portLabel: 'Port 2',
            specs: 'CCS\n150 kW',
            selected: selectedPortIndex == 1,
            onTap: () => onPortSelected(1),
          ),
          10.horizontalSpace,
          PortCard(
            ui: ui,
            portLabel: 'Port 3',
            specs: 'Type 2,\n22kW',
            selected: selectedPortIndex == 2,
            onTap: () => onPortSelected(2),
          ),
        ],
      ),
    );
  }
}

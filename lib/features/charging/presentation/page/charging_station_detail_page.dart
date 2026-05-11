import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../view/charging_station_detail_mobile_view.dart';
import '../../../map/domain/entities/hubco_location_entity.dart';

class ChargingStationDetailPage extends StatelessWidget {
  const ChargingStationDetailPage({
    super.key,
    required this.station,
  });

  final HubcoLocationEntity? station;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      mobile: ChargingStationDetailMobileView(
        station: station,
      ),
    );
  }
}

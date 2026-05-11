import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_amenity_chip_widget.dart';

class ChargingStationAmenitiesWidget extends StatelessWidget {
  const ChargingStationAmenitiesWidget({
    super.key,
    required this.amenities,
  });

  final List<AmenityModel> amenities;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < amenities.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            ChargingStationAmenityChipWidget(amenity: amenities[i]),
          ],
        ],
      ),
    );
  }
}

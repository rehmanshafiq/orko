import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/book_slot_mobile_view.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Route arguments for `/book-slot`, carrying the station plus the vehicle
/// resolved by the compatibility gate (sent as `vehicle_id` on booking).
class BookSlotArgs {
  const BookSlotArgs({required this.station, this.vehicleId});

  final HubcoLocationEntity station;
  final int? vehicleId;
}

class BookSlotPage extends StatelessWidget {
  const BookSlotPage({
    super.key,
    this.locationId,
    this.vehicleId,
    this.stationName,
    this.stationAddress,
  });

  /// Charging location id used by every booking call. Null when opened without
  /// a station context — booking is disabled and a hint is shown.
  final int? locationId;

  /// User vehicle resolved by the compatibility gate; sent as `vehicle_id`.
  final int? vehicleId;
  final String? stationName;
  final String? stationAddress;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingCubit>()
        ..start(
          locationId: locationId,
          vehicleId: vehicleId,
          stationName: stationName,
          stationAddress: stationAddress,
        ),
      child: BookSlotMobileView(
        stationName: stationName,
        stationAddress: stationAddress,
      ),
    );
  }
}

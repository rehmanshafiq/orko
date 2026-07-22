import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/book_slot_mobile_view.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Route arguments for `/book-slot`, carrying the station plus the vehicle
/// resolved by the compatibility gate (sent as `vehicle_id` on booking).
class BookSlotArgs {
  const BookSlotArgs({
    required this.station,
    this.vehicleId,
    this.fromTrip = false,
    this.openingTime = '',
    this.closingTime = '',
  });

  final HubcoLocationEntity station;
  final int? vehicleId;

  /// True when opened from the Trip planner's Pre-book flow.
  final bool fromTrip;

  /// Station opening time (`HH:mm:ss`) used to disable off-hours slots.
  final String openingTime;

  /// Station closing time (`HH:mm:ss`) used to disable off-hours slots.
  final String closingTime;
}

class BookSlotPage extends StatelessWidget {
  const BookSlotPage({
    super.key,
    this.locationId,
    this.vehicleId,
    this.stationName,
    this.stationAddress,
    this.fromTrip = false,
    this.openingTime = '',
    this.closingTime = '',
  });

  /// Charging location id used by every booking call. Null when opened without
  /// a station context — booking is disabled and a hint is shown.
  final int? locationId;

  /// User vehicle resolved by the compatibility gate; sent as `vehicle_id`.
  final int? vehicleId;
  final String? stationName;
  final String? stationAddress;

  /// True when opened from the Trip planner — carried to the success screen so
  /// closing it returns to the Trip planner instead of Home.
  final bool fromTrip;

  /// Station opening time (`HH:mm:ss`) used to disable off-hours slots.
  final String openingTime;

  /// Station closing time (`HH:mm:ss`) used to disable off-hours slots.
  final String closingTime;

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
        fromTrip: fromTrip,
        openingTime: openingTime,
        closingTime: closingTime,
      ),
    );
  }
}

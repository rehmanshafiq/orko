import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';

class TripMapCardWidget extends StatelessWidget {
  const TripMapCardWidget({
    required this.plan,
    required this.startIcon,
    required this.endIcon,
    required this.stopIcon,
    required this.darkMapStyle,
    required this.onMapCreated,
    this.onStopTap,
    super.key,
  });

  final TripPlanModel? plan;
  final BitmapDescriptor? startIcon;
  final BitmapDescriptor? endIcon;
  final BitmapDescriptor? stopIcon;
  final String darkMapStyle;
  final ValueChanged<GoogleMapController> onMapCreated;

  /// Called with the stop index when a charger marker is tapped.
  final ValueChanged<int>? onStopTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final routePoints =
        plan == null ? const <LatLng>[] : plan!.waypoints.map((p) => LatLng(p.lat, p.lng)).toList();

    final initialTarget = routePoints.isEmpty
        ? const LatLng(30.3753, 69.3451)
        : LatLng(
            routePoints.map((p) => p.latitude).reduce((a, b) => a + b) / routePoints.length,
            routePoints.map((p) => p.longitude).reduce((a, b) => a + b) / routePoints.length,
          );

    final markers = <Marker>{
      if (routePoints.isNotEmpty)
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          icon: startIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: plan?.start.name ?? 'Start'),
        ),
      if (routePoints.length > 1)
        Marker(
          markerId: const MarkerId('end'),
          position: routePoints.last,
          icon: endIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: plan?.end.name ?? 'Destination'),
        ),
      if (plan != null)
        for (var i = 0; i < plan!.stops.length; i++)
          Marker(
            markerId: MarkerId('stop-${plan!.stops[i].id}'),
            position: LatLng(
              plan!.stops[i].latitude,
              plan!.stops[i].longitude,
            ),
            icon: stopIcon ?? BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: plan!.stops[i].name,
              snippet: plan!.stops[i].address,
              onTap: onStopTap == null ? null : () => onStopTap!(i),
            ),
            onTap: onStopTap == null ? null : () => onStopTap!(i),
          ),
    };

    return Container(
      height: 312.h,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialTarget,
                  zoom: 6.5,
                ),
                style: ui.isLight ? null : darkMapStyle,
                compassEnabled: false,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                // Claim gestures so the parent ListView doesn't intercept
                // pan / pinch on the map.
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    EagerGestureRecognizer.new,
                  ),
                },
                onMapCreated: onMapCreated,
                markers: markers,
                polylines: {
                  if (routePoints.length > 1)
                    Polyline(
                      polylineId: const PolylineId('trip-route'),
                      points: routePoints,
                      color: AppColors.mapPinBlueColor.withValues(alpha: 0.42),
                      width: 4,
                    ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


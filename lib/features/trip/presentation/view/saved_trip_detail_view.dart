import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_saved_trip_detail_usecase.dart';

/// Loads and shows a single saved trip (`GET /trips/<id>/`).
class SavedTripDetailView extends StatefulWidget {
  const SavedTripDetailView({required this.tripId, super.key});

  final int tripId;

  @override
  State<SavedTripDetailView> createState() => _SavedTripDetailViewState();
}

enum _Status { loading, failure, success }

class _SavedTripDetailViewState extends State<SavedTripDetailView> {
  _Status _status = _Status.loading;
  String? _error;
  SavedTripEntity? _trip;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
    });
    final result = await sl<GetSavedTripDetailUseCase>()(widget.tripId);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _status = _Status.failure;
        _error = failure.message;
      }),
      (trip) => setState(() {
        _status = _Status.success;
        _trip = trip;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        title: AppText(
          'Trip Details',
          color: ui.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
      ),
      body: SafeArea(child: _body(ui)),
    );
  }

  Widget _body(AppUiColors ui) {
    switch (_status) {
      case _Status.loading:
        return const Center(child: CircularProgressIndicator());
      case _Status.failure:
        return Center(
          child: Padding(
            padding: AppUtils.horizontal16Padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  _error ?? 'Trip plan not found.',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                  textAlign: TextAlign.center,
                ),
                12.verticalSpace,
                TextButton(
                  onPressed: _load,
                  child: AppText(
                    'Retry',
                    color: ui.brandPrimary,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
          ),
        );
      case _Status.success:
        final trip = _trip!;
        return ListView(
          padding: AppUtils.horizontal16Padding,
          children: [
            12.verticalSpace,
            if (!trip.isFeasible)
              _Banner(
                color: AppColors.ratingStarColor,
                text:
                    'This trip is marked infeasible — the stops below are the partial route reached.',
              ),
            if (!trip.isFeasible) 12.verticalSpace,
            _summary(ui, trip),
            16.verticalSpace,
            AppText(
              'Charging Stops',
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight700,
            ),
            10.verticalSpace,
            if (trip.stops.isEmpty)
              AppText(
                'No charging stops on this trip.',
                color: ui.textMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              )
            else
              for (final stop in trip.stops) ...[
                _StopCard(stop: stop, currency: trip.currency),
                8.verticalSpace,
              ],
            24.verticalSpace,
          ],
        );
    }
  }

  Widget _summary(AppUiColors ui, SavedTripEntity trip) {
    String km(double v) => '${v.round()} km';
    String mins(double v) => '${v.round()} min';
    String money(double v) => '${trip.currency} ${v.round()}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(ui, 'From', trip.originAddress ?? _coords(trip.originLatitude, trip.originLongitude)),
          6.verticalSpace,
          _row(ui, 'To', trip.destinationAddress ?? _coords(trip.destinationLatitude, trip.destinationLongitude)),
          12.verticalSpace,
          Divider(color: ui.borderSubtle, height: 1),
          12.verticalSpace,
          _row(ui, 'Distance', km(trip.totalDistanceKm)),
          6.verticalSpace,
          _row(ui, 'Drive time', mins(trip.totalDriveMinutes)),
          6.verticalSpace,
          _row(ui, 'Charging time', mins(trip.totalChargingMinutes)),
          6.verticalSpace,
          _row(ui, 'Total cost', money(trip.totalCost)),
          6.verticalSpace,
          _row(ui, 'Start charge', '${trip.startSoc.round()}%'),
        ],
      ),
    );
  }

  String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

  Widget _row(AppUiColors ui, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96.w,
          child: AppText(
            label,
            color: ui.textMuted,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        ),
        Expanded(
          child: AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, required this.currency});

  final TripStopEntity stop;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${stop.sequence}. ${stop.locationName}',
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((stop.locationAddress ?? '').isNotEmpty) ...[
            2.verticalSpace,
            AppText(
              stop.locationAddress!,
              color: ui.textMuted,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
          10.verticalSpace,
          Row(
            children: [
              Expanded(child: _metric(ui, 'Arrive', '${stop.arrivalSoc.round()}%')),
              Expanded(child: _metric(ui, 'Depart', '${stop.departureSoc.round()}%')),
              Expanded(child: _metric(ui, 'Time', '${stop.chargingMinutes.round()} min')),
              Expanded(child: _metric(ui, 'Cost', '$currency ${stop.cost.round()}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(AppUiColors ui, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          value,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight700,
        ),
        2.verticalSpace,
        AppText(
          label,
          color: ui.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight400,
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18.sp),
          8.horizontalSpace,
          Expanded(
            child: AppText(
              text,
              color: color,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ],
      ),
    );
  }
}

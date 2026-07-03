import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/delete_saved_trip_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_saved_trip_detail_usecase.dart';
import 'package:orko_hubco/features/trip/presentation/view/trip_planner_mobile_view.dart';

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

  /// True while the delete request is in flight — guards against double taps
  /// and drives the app-bar spinner.
  bool _deleting = false;

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

  /// Confirms, then deletes this trip. On success shows a toast and pops back
  /// with `true` so the Saved Trips list can refresh.
  Future<void> _onDelete() async {
    if (_deleting) return;

    final confirmed = await _confirmDelete();
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    final result = await sl<DeleteSavedTripUseCase>()(widget.tripId);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.removeColor,
            ),
          );
      },
      (message) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        // Signal the previous (Saved Trips) screen to reload its list.
        Navigator.of(context).pop(true);
      },
    );
  }

  /// Opens the trip planner in edit mode, pre-filled with this trip. When the
  /// edit succeeds the planner pops with `true`, so we reload to show the
  /// freshly recomputed stops/summary.
  Future<void> _onEdit() async {
    final trip = _trip;
    if (trip == null || _deleting) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TripPlannerMobileView(editTrip: trip),
      ),
    );
    if (updated == true && mounted) _load();
  }

  Future<bool?> _confirmDelete() {
    final ui = AppUiColors.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ui.scaffoldBackground,
        title: AppText(
          'Delete Trip',
          color: ui.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
        content: AppText(
          'Are you sure you want to delete this saved trip? This action cannot '
          'be undone.',
          color: ui.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: AppText(
              'Cancel',
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: AppText(
              'Delete',
              color: AppColors.removeColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
        ],
      ),
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
        actions: [
          // Edit + Delete are only actionable once a trip has loaded, and are
          // hidden while a delete is in flight.
          if (_status == _Status.success && !_deleting)
            TextButton(
              onPressed: _onEdit,
              child: AppText(
                'Edit',
                color: ui.brandPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          if (_status == _Status.success)
            _deleting
                ? Padding(
                    padding: EdgeInsets.only(right: 16.w),
                    child: Center(
                      child: SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.removeColor,
                        ),
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _onDelete,
                    child: AppText(
                      'Delete',
                      color: AppColors.removeColor,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
        ],
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
                _StopCard(stop: stop),
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
    String money(double v) => AppHelpers.formatRs(v.round());

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
          _row(ui, 'Estimated Charging Time', mins(trip.totalChargingMinutes)),
          6.verticalSpace,
          _row(ui, 'Estimated Charging Cost', money(trip.totalCost)),
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
          width: 170.w,
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
  const _StopCard({required this.stop});

  final TripStopEntity stop;

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
              Expanded(child: _metric(ui, 'Cost', AppHelpers.formatRs(stop.cost.round()))),
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

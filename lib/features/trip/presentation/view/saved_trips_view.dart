import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_saved_trips_usecase.dart';
import 'package:orko_hubco/features/trip/presentation/view/saved_trip_detail_view.dart';

/// Lists the user's saved trips (`GET /trips/`), newest first.
class SavedTripsView extends StatefulWidget {
  const SavedTripsView({super.key});

  @override
  State<SavedTripsView> createState() => _SavedTripsViewState();
}

enum _Status { loading, failure, success }

class _SavedTripsViewState extends State<SavedTripsView> {
  _Status _status = _Status.loading;
  String? _error;
  List<SavedTripEntity> _trips = const [];

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
    final result = await sl<GetSavedTripsUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _status = _Status.failure;
        _error = failure.message;
      }),
      (trips) => setState(() {
        _status = _Status.success;
        _trips = trips;
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
          'Saved Trips',
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
                  _error ?? 'Could not load your saved trips.',
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
        if (_trips.isEmpty) {
          return Center(
            child: Padding(
              padding: AppUtils.horizontal16Padding,
              child: AppText(
                'No saved trips yet. Plan a trip and tap Save to keep it here.',
                color: ui.textMuted,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: AppUtils.horizontal16Padding.add(
              EdgeInsets.symmetric(vertical: 12.h),
            ),
            itemCount: _trips.length,
            separatorBuilder: (_, __) => 10.verticalSpace,
            itemBuilder: (_, i) => _TripCard(
              trip: _trips[i],
              onTap: () async {
                final deleted = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SavedTripDetailView(tripId: _trips[i].id),
                  ),
                );
                // The detail screen returns `true` after a successful delete;
                // refresh the list so the removed trip disappears.
                if (deleted == true && mounted) _load();
              },
            ),
          ),
        );
    }
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final SavedTripEntity trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final from = trip.originAddress ??
        '${trip.originLatitude.toStringAsFixed(3)}, ${trip.originLongitude.toStringAsFixed(3)}';
    final to = trip.destinationAddress ??
        '${trip.destinationLatitude.toStringAsFixed(3)}, ${trip.destinationLongitude.toStringAsFixed(3)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: AppUtils.vertical10Horizontal12Padding,
        decoration: BoxDecoration(
          color: ui.searchBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: ui.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    '$from  →  $to',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!trip.isFeasible) ...[
                  6.horizontalSpace,
                  _Pill(
                    text: 'infeasible',
                    color: AppColors.ratingStarColor,
                  ),
                ],
              ],
            ),
            8.verticalSpace,
            Row(
              children: [
                _meta(ui, '${trip.totalDistanceKm.round()} km'),
                _dot(ui),
                _meta(ui, AppHelpers.formatRs(trip.totalCost.round())),
                _dot(ui),
                _meta(ui, '${trip.stops.length} stops'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(AppUiColors ui, String text) => AppText(
        text,
        color: ui.textMuted,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight400,
      );

  Widget _dot(AppUiColors ui) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: AppText(
          '·',
          color: ui.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight400,
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      child: AppText(
        text,
        color: color,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }
}

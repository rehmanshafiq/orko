import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_event.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_state.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/station_reviews_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_amenities_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_banner_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_bottom_actions_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_glass_button_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_meta_row_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_operating_hours_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_ports_list_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_section_title_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_reviews_section_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Charging hub detail — layout matches product reference (dark theme).
class ChargingStationDetailMobileView extends StatelessWidget {
  const ChargingStationDetailMobileView({
    super.key,
    required this.station,
  });

  final HubcoLocationEntity? station;

  @override
  Widget build(BuildContext context) {
    final hub = station;
    final ui = AppUiColors.of(context);
    if (hub == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return Scaffold(
        backgroundColor: ui.scaffoldBackground,
        body: Center(
          child: AppText(
            'Invalid station',
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ChargingStationDetailBloc>()
            ..add(
              ChargingStationDetailRequested(
                stationId: hub.id.toString(),
                latitude: hub.latitude,
                longitude: hub.longitude,
              ),
            ),
        ),
        // Reviews load in parallel keyed by the station's location id.
        BlocProvider(
          create: (_) => sl<StationReviewsCubit>(param1: hub.id)..load(),
        ),
      ],
      child: BlocConsumer<ChargingStationDetailBloc, ChargingStationDetailState>(
        listenWhen: (previous, current) =>
            previous.favoriteEventId != current.favoriteEventId &&
            current.favoriteError.isNotEmpty,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.favoriteError)),
            );
        },
        builder: (context, state) {
          final availableCount = state.ports.where((p) => p.available).length;
          final totalPorts = state.ports.length;
          final stationName = state.name.isNotEmpty ? state.name : hub.name;

          return Scaffold(
            backgroundColor: ui.scaffoldBackground,
            body: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 160.h,
                        pinned: true,
                        stretch: true,
                        backgroundColor: ui.scaffoldBackground,
                        surfaceTintColor: AppColors.transparentColor,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        automaticallyImplyLeading: false,
                        leadingWidth: 56.w,
                        leading: Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ChargingStationGlassButtonWidget(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => context.pop(),
                            ),
                          ),
                        ),
                        actions: [
                          if (!(state.isLoading && !state.isSuccess))
                            Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: ChargingStationGlassButtonWidget(
                                icon: state.favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: () {
                                  // Favouriting requires an account — prompt a
                                  // guest to log in instead of calling the
                                  // auth-only favourites endpoint (which 401s).
                                  if (AppStorage.isGuest) {
                                    AuthRequiredDialog.show(
                                      context,
                                      feature: 'favorites',
                                      message:
                                          'You\'re browsing as a guest. Please log in or create an account to save favourite stations.',
                                    );
                                    return;
                                  }
                                  context
                                      .read<ChargingStationDetailBloc>()
                                      .add(const ChargingStationDetailFavoriteToggled());
                                },
                                iconColor: state.favorite
                                    ? ui.brandPrimary
                                    : ui.textPrimary,
                              ),
                            ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          stretchModes: const [
                            StretchMode.zoomBackground,
                            StretchMode.blurBackground,
                          ],
                          background: ChargingStationBannerWidget(
                            bannerImage: state.bannerImage,
                          ),
                        ),
                      ),
                      if (state.isLoading && !state.isSuccess)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: ui.brandPrimary,
                            ),
                          ),
                        )
                      else if (state.isFailure)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ErrorView(
                            message: state.errorMessage,
                            stationName: stationName,
                            onRetry: () => context
                                .read<ChargingStationDetailBloc>()
                                .add(
                                  ChargingStationDetailRequested(
                                    stationId: hub.id.toString(),
                                    latitude: hub.latitude,
                                    longitude: hub.longitude,
                                  ),
                                ),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: AppUtils.horizontal16Padding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                16.verticalSpace,
                                AppText(
                                  stationName,
                                  color: ui.textPrimary,
                                  fontSize: FontSizes.font26Sp,
                                  fontWeight: FontWeights.weight700,
                                ),
                                6.verticalSpace,
                                ChargingStationMetaRowWidget(
                                  station: hub,
                                  availableCount: availableCount,
                                  totalPorts: totalPorts,
                                  rating: state.averageRating,
                                  reviewCount: state.totalReviews,
                                ),
                                4.verticalSpace,
                                const Divider(),
                                4.verticalSpace,
                                const ChargingStationSectionTitleWidget(
                                  title: 'Charger Ports',
                                ),
                                8.verticalSpace,
                                if (state.ports.isEmpty)
                                  _EmptyText(
                                    text: 'No charger ports available',
                                  )
                                else
                                  ChargingStationPortsListWidget(
                                    ports: state.ports,
                                    selectedPortIndex: state.selectedPortIndex,
                                    onAvailablePortTap: (i) => context
                                        .read<ChargingStationDetailBloc>()
                                        .add(ChargingStationDetailPortSelected(i)),
                                  ),
                                4.verticalSpace,
                                const Divider(),
                                4.verticalSpace,
                                const ChargingStationSectionTitleWidget(
                                  title: 'Amenities',
                                ),
                                6.verticalSpace,
                                if (state.amenities.isEmpty)
                                  _EmptyText(text: 'No amenities listed')
                                else
                                  ChargingStationAmenitiesWidget(
                                    amenities: state.amenities,
                                  ),
                                8.verticalSpace,
                                const Divider(),
                                4.verticalSpace,
                                const ChargingStationSectionTitleWidget(
                                  title: 'Operating Hours',
                                ),
                                8.verticalSpace,
                                ChargingStationOperatingHoursWidget(
                                  info: state.operatingHoursInfo,
                                  fallbackText: state.operatingHours,
                                ),
                                12.verticalSpace,
                                const ChargingStationSectionTitleWidget(
                                  title: 'Pricing',
                                ),
                                6.verticalSpace,
                                AppText(
                                  state.pricing.isNotEmpty
                                      ? state.pricing
                                      : 'Not available',
                                  color: ui.textSecondary,
                                  fontSize: FontSizes.font14Sp,
                                  fontWeight: FontWeights.weight400,
                                ),
                                8.verticalSpace,
                                const ChargingStationSectionTitleWidget(
                                  title: 'Contact No.',
                                ),
                                6.verticalSpace,
                                AppText(
                                  state.contactNumber.isNotEmpty
                                      ? state.contactNumber
                                      : 'Not available',
                                  color: ui.textSecondary,
                                  fontSize: FontSizes.font14Sp,
                                  fontWeight: FontWeights.weight400,
                                ),
                                4.verticalSpace,
                                const Divider(),
                                10.verticalSpace,
                                const StationReviewsSectionWidget(),
                                50.verticalSpace,
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ChargingStationBottomActionsWidget(
                  station: hub,
                  latitude: state.latitude ?? hub.latitude,
                  longitude: state.longitude ?? hub.longitude,
                  isEnabled: state.isSuccess,
                  isClosed: state.isClosed,
                  isThirdParty: state.isThirdParty,
                  chargePointId: state.chargePointId,
                  openingTime: state.openingTime,
                  closingTime: state.closingTime,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return AppText(
      text,
      color: ui.textSecondary,
      fontSize: FontSizes.font12Sp,
      fontWeight: FontWeights.weight400,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.stationName,
    required this.onRetry,
  });

  final String message;
  final String stationName;
  final VoidCallback onRetry;

  /// Never show raw exception text (DioException/SocketException dumps) —
  /// map it to a user-readable message instead.
  String get _displayMessage {
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    final looksLikeRawError = message.contains('DioException') ||
        message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('Connection refused');
    if (looksLikeRawError) {
      return 'No internet connection. '
          'Please check your network and try again.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: AppUtils.horizontal16Padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: ui.textSecondary,
            size: 40.r,
          ),
          12.verticalSpace,
          AppText(
            'Unable to load $stationName',
            color: ui.textPrimary,
            fontSize: FontSizes.font16Sp,
            fontWeight: FontWeights.weight600,
            textAlign: TextAlign.center,
          ),
          6.verticalSpace,
          AppText(
            _displayMessage,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
          16.verticalSpace,
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: ui.textPrimary,
              side: BorderSide(color: ui.textPrimary.withValues(alpha: 0.85)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32.r),
              ),
            ),
            child: AppText(
              'Retry',
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
            ),
          ),
        ],
      ),
    );
  }
}

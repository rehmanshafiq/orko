import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_event.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_amenities_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_banner_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_bottom_actions_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_glass_button_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_meta_row_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_ports_list_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_reviews_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_section_title_widget.dart';
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

    return BlocProvider(
      create: (_) => ChargingStationDetailBloc(),
      child: BlocBuilder<ChargingStationDetailBloc, ChargingStationDetailState>(
        builder: (context, state) {
          final availableCount = state.ports.where((p) => p.available).length;
          final totalPorts = state.ports.length;

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
                          Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ChargingStationGlassButtonWidget(
                              icon: state.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              onTap: () => context
                                  .read<ChargingStationDetailBloc>()
                                  .add(const ChargingStationDetailFavoriteToggled()),
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
                          background: const ChargingStationBannerWidget(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: AppUtils.horizontal16Padding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              16.verticalSpace,
                              AppText(
                                hub.name,
                                color: ui.textPrimary,
                                fontSize: FontSizes.font26Sp,
                                fontWeight: FontWeights.weight700,
                              ),
                              6.verticalSpace,
                              ChargingStationMetaRowWidget(
                                station: hub,
                                availableCount: availableCount,
                                totalPorts: totalPorts,
                              ),
                              4.verticalSpace,
                              const Divider(),
                              4.verticalSpace,
                              const ChargingStationSectionTitleWidget(
                                title: 'Charger Ports',
                              ),
                              8.verticalSpace,
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
                              ChargingStationAmenitiesWidget(
                                amenities: state.amenities,
                              ),
                              8.verticalSpace,
                              const Divider(),
                              4.verticalSpace,
                              const ChargingStationSectionTitleWidget(
                                title: 'Operating Hours',
                              ),
                              4.verticalSpace,
                              AppText(
                                '24 hours 7 days',
                                color: ui.textSecondary,
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight400,
                              ),
                              8.verticalSpace,
                              const ChargingStationSectionTitleWidget(
                                title: 'Pricing',
                              ),
                              6.verticalSpace,
                              AppText(
                                'Rs 45 per kWh, minimum 30 minutes',
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
                                '03123456789',
                                color: ui.textSecondary,
                                fontSize: FontSizes.font14Sp,
                                fontWeight: FontWeights.weight400,
                              ),
                              4.verticalSpace,
                              const Divider(),
                              6.verticalSpace,
                              const ChargingStationSectionTitleWidget(
                                title: 'Reviews',
                              ),
                              6.verticalSpace,
                              ChargingStationReviewsWidget(
                                reviews: state.reviews,
                              ),
                              50.verticalSpace,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const ChargingStationBottomActionsWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}

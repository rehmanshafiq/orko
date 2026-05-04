import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Charging hub detail — layout matches product reference (dark theme).
class ChargingStationDetailScreen extends StatefulWidget {
  const ChargingStationDetailScreen({
    super.key,
    required this.station,
  });

  final HubcoLocationEntity? station;

  @override
  State<ChargingStationDetailScreen> createState() =>
      _ChargingStationDetailScreenState();
}

class _ChargingStationDetailScreenState
    extends State<ChargingStationDetailScreen> {
  bool _favorite = false;
  /// Highlighted port row (matches design: first row selected by default).
  int _selectedPortIndex = 0;

  static const List<_ChargerPort> _ports = [
    _ChargerPort(label: 'CCS, 150 kW', price: 'Rs 45 per kWh', available: true),
    _ChargerPort(
      label: 'CHAdeMO, 150 kW',
      price: 'Rs 45 per kWh',
      available: false,
    ),
    _ChargerPort(label: 'Type 2, 22 kW', price: 'Rs 38 per kWh', available: true),
  ];

  static const List<_Amenity> _amenities = [
    _Amenity(Icons.wifi_rounded, 'WiFi'),
    _Amenity(Icons.wc_rounded, 'Restroom'),
    _Amenity(Icons.local_cafe_rounded, 'Cafe'),
    _Amenity(Icons.local_parking_rounded, 'Parking'),
    _Amenity(Icons.schedule_rounded, '24 Hours'),
  ];

  static const List<_Review> _reviews = [
    _Review(
      name: 'Rahul S.',
      text: 'Fast charging and clean location. Highly recommend!',
      rating: 5,
    ),
    _Review(
      name: 'Ayesha K.',
      text: 'Easy to find on M2. Staff was helpful.',
      rating: 4,
    ),
    _Review(
      name: 'Omar M.',
      text: 'Good rates compared to other hubs nearby.',
      rating: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final station = widget.station;
    if (station == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return Scaffold(
        backgroundColor: AppColors.blackColor,
        body: Center(
          child: AppText(
            'Invalid station',
            color: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
          ),
        ),
      );
    }

    final availableCount = _ports.where((p) => p.available).length;
    final totalPorts = _ports.length;

    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  expandedHeight: 280.h,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.blackColor,
                  surfaceTintColor: AppColors.transparentColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  leadingWidth: 56.w,
                  leading: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _glassCircleButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.pop(),
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _glassCircleButton(
                        icon: _favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        onTap: () => setState(() => _favorite = !_favorite),
                        iconColor: _favorite
                            ? AppColors.primaryDarkColor
                            : AppColors.whiteColor,
                      ),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: _bannerBackground(),
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
                          station.name,
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font22Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        6.verticalSpace,
                        AppText(
                          station.address,
                          color: AppColors.iconsGreyColor,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        10.verticalSpace,
                        _buildMetaRow(station, availableCount, totalPorts),
                        22.verticalSpace,
                        AppText(
                          'Charger Ports',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        _buildChargerPortsList(),
                        22.verticalSpace,
                        AppText(
                          'Amenities',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        _buildAmenitiesChips(),
                        22.verticalSpace,
                        AppText(
                          'Operating Hours',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        6.verticalSpace,
                        AppText(
                          '24 hours 7 days',
                          color: AppColors.iconsGreyColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        16.verticalSpace,
                        Divider(
                          height: 1,
                          color: AppColors.whiteColor.withValues(alpha: 0.08),
                        ),
                        16.verticalSpace,
                        AppText(
                          'Pricing',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        6.verticalSpace,
                        AppText(
                          'Rs 45 per kWh, minimum 30 minutes',
                          color: AppColors.iconsGreyColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        22.verticalSpace,
                        AppText(
                          'Reviews',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        _buildReviewsRow(),
                        50.verticalSpace,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(context),
        ],
      ),
    );
  }

  /// Banner only — [SliverAppBar] + [FlexibleSpaceBar] drive collapse / parallax.
  Widget _bannerBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.chargingStationBanner),
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.blackColor.withValues(alpha: 0.25),
                AppColors.blackColor.withValues(alpha: 0.72),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          height: 44.r,
          width: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blackColor.withValues(alpha: 0.35),
            border: Border.all(
              color: AppColors.whiteColor.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.whiteColor,
            size: 22.r,
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    HubcoLocationEntity station,
    int availableCount,
    int totalPorts,
  ) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: AppColors.ratingStarColor, size: 18.r),
            4.horizontalSpace,
            AppText(
              '4.8 (127 reviews)',
              color: AppColors.iconsGreyColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_rounded,
              color: AppColors.mapPinBlueColor,
              size: 18.r,
            ),
            4.horizontalSpace,
            AppText(
              '2.3 km',
              color: AppColors.mapPinBlueColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
        ),
        _availabilityBadge(station, availableCount, totalPorts),
      ],
    );
  }

  Widget _availabilityBadge(
    HubcoLocationEntity station,
    int available,
    int total,
  ) {
    final label = station.status
        ? 'Available $available of $total'
        : 'Unavailable';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: station.status
            ? AppColors.primaryDarkColor.withValues(alpha: 0.18)
            : AppColors.slotBookedBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: station.status
              ? AppColors.primaryDarkColor
              : AppColors.slotBookedBackgroundColor,
        ),
      ),
      child: AppText(
        label,
        color: station.status
            ? AppColors.primaryDarkColor
            : AppColors.whiteColor,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
        maxLines: 2,
        textAlign: TextAlign.end,
      ),
    );
  }

  /// Charger Ports: flat list, selection highlight, divider inset past icon.
  Widget _buildChargerPortsList() {
    final iconSize = 44.r;
    final iconGap = 12.w;
    final dividerLeft = iconSize + iconGap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _ports.length; i++) ...[
          Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () => setState(() => _selectedPortIndex = i),
              splashColor: AppColors.whiteColor.withValues(alpha: 0.06),
              highlightColor: AppColors.whiteColor.withValues(alpha: 0.04),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: i == _selectedPortIndex
                      ? AppColors.whiteColor.withValues(alpha: 0.07)
                      : AppColors.transparentColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _portPlugIcon(iconSize),
                    iconGap.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: AppText(
                                  _ports[i].label,
                                  color: AppColors.whiteColor,
                                  fontSize: FontSizes.font14Sp,
                                  fontWeight: FontWeights.weight600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              8.horizontalSpace,
                              _portStatusChip(_ports[i].available),
                            ],
                          ),
                          4.verticalSpace,
                          AppText(
                            _ports[i].price,
                            color: AppColors.iconsGreyColor,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight400,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i < _ports.length - 1)
            Padding(
              padding: EdgeInsets.only(left: dividerLeft),
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppColors.whiteColor.withValues(alpha: 0.08),
              ),
            ),
        ],
      ],
    );
  }

  Widget _portPlugIcon(double diameter) {
    return Container(
      height: diameter,
      width: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.whiteColor.withValues(alpha: 0.10),
      ),
      child: Icon(
        Icons.ev_station_rounded,
        color: AppColors.whiteColor.withValues(alpha: 0.88),
        size: 22.r,
      ),
    );
  }

  Widget _portStatusChip(bool available) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primaryDarkColor.withValues(alpha: 0.14)
            : AppColors.slotBusyYellowColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: available
              ? AppColors.primaryDarkColor.withValues(alpha: 0.45)
              : AppColors.slotBusyYellowColor.withValues(alpha: 0.5),
        ),
      ),
      child: AppText(
        available ? 'Available' : 'Occupied',
        color: available
            ? AppColors.primaryDarkColor
            : AppColors.slotBusyYellowColor,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }

  Widget _buildAmenitiesChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _amenities.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            _amenityChip(_amenities[i]),
          ],
        ],
      ),
    );
  }

  Widget _amenityChip(_Amenity a) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            a.icon,
            size: 16.r,
            color: AppColors.whiteColor.withValues(alpha: 0.85),
          ),
          6.horizontalSpace,
          AppText(
            a.label,
            color: AppColors.whiteColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsRow() {
    return Container(
      height: 148.h,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => 12.horizontalSpace,
        itemBuilder: (context, index) => _reviewCard(_reviews[index]),
      ),
    );
  }

  Widget _reviewCard(_Review r) {
    return Container(
      width: 260.w,
      height: 248.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                Icon(
                  i < r.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16.r,
                  color: AppColors.ratingStarColor,
                ),
                if (i < 4) 2.horizontalSpace,
              ],
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: AppColors.greyColor.withValues(alpha: 0.4),
                child: Center(
                  child: AppText(
                    r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                    color: AppColors.whiteColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: AppText(
                  r.name,
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          8.verticalSpace,
          AppText(
            r.text,
            color: AppColors.whiteColor.withValues(alpha: 0.88),
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  AppHelpers.showSnackBar(
                    context,
                    'Opening directions…',
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.whiteColor,
                  side: BorderSide(
                    color: AppColors.whiteColor.withValues(alpha: 0.85),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation_rounded, size: 18.r),
                    8.horizontalSpace,
                    AppText(
                      'Directions',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ],
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: PrimaryButtonWidget(
                text: 'Book Slot',
                onPress: () => context.go('/bookings'),
                buttonWidth: double.infinity,
                buttonHeight: 48.h,
                cornerRadius: 12.r,
                buttonColor: AppColors.primaryDarkColor,
                textColor: AppColors.blackColor,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargerPort {
  const _ChargerPort({
    required this.label,
    required this.price,
    required this.available,
  });

  final String label;
  final String price;
  final bool available;
}

class _Amenity {
  const _Amenity(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _Review {
  const _Review({
    required this.name,
    required this.text,
    required this.rating,
  });

  final String name;
  final String text;
  final double rating;
}

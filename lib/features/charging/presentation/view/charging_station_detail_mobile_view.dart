import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_images.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_event.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_state.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class ChargingStationDetailMobileView extends StatelessWidget {
  const ChargingStationDetailMobileView({
    super.key,
    required this.station,
  });

  final HubcoLocationEntity? station;

  @override
  Widget build(BuildContext context) {
    final hub = station;
    if (hub == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return Scaffold(
        backgroundColor: context.revampedTheme.stationDetailBackground,
        body: Center(
          child: AppText(
            'Invalid station',
            color: context.revampedTheme.textPrimary,
            fontSize: FontSizes.font14Sp,
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => ChargingStationDetailBloc(),
      child: BlocBuilder<ChargingStationDetailBloc, ChargingStationDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.revampedTheme.stationDetailBackground,
            body: Column(
              children: [
                _StationDetailTopBar(
                  isFavorite: state.favorite,
                  onBack: () => context.pop(),
                  onFavoriteToggle: () => context
                      .read<ChargingStationDetailBloc>()
                      .add(const ChargingStationDetailFavoriteToggled()),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: AppUtils.horizontal16Padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        12.verticalSpace,
                        _HeroImageCard(station: hub),
                        24.verticalSpace,
                        _ChargerAvailabilitySection(
                          ports: state.ports,
                          selectedPortIndex: state.selectedPortIndex,
                          onPortTap: (index) => context
                              .read<ChargingStationDetailBloc>()
                              .add(ChargingStationDetailPortSelected(index)),
                        ),
                        16.verticalSpace,
                        const _PricingSection(),
                        24.verticalSpace,
                        _AmenitiesSection(amenities: state.amenities),
                        24.verticalSpace,
                        _LocationSection(station: hub),
                        96.verticalSpace,
                      ],
                    ),
                  ),
                ),
                const _StationDetailBottomBar(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StationDetailTopBar extends StatelessWidget {
  const _StationDetailTopBar({
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteToggle,
  });

  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: context.revampedTheme.topBarBackground,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.revampedTheme.textPrimary,
                size: 24.sp,
              ),
            ),
            Expanded(
              child: Center(
                child: AppText(
                  'HUBCO',
                  color: context.revampedTheme.stationDetailBrandGreen,
                  fontSize: FontSizes.font20Sp,
                  fontWeight: FontWeights.weight700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: onFavoriteToggle,
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite
                    ? context.revampedTheme.stationDetailBrandGreen
                    : context.revampedTheme.textPrimary,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImageCard extends StatelessWidget {
  const _HeroImageCard({required this.station});

  final HubcoLocationEntity station;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: SizedBox(
        height: 220.h,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImages.chargingStationBanner),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.blackColor.withValues(alpha: 0.08),
                    AppColors.blackColor.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: context.revampedTheme.mintBadgeBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AppText(
                      'SUPERCHARGER',
                      color: context.revampedTheme.availableGreen,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  AppText(
                    station.name,
                    color: AppColors.whiteColor,
                    fontSize: FontSizes.font24Sp,
                    fontWeight: FontWeights.weight700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  6.verticalSpace,
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: AppColors.whiteColor.withValues(alpha: 0.92),
                        size: 16.sp,
                      ),
                      4.horizontalSpace,
                      Expanded(
                        child: AppText(
                          station.address,
                          color: AppColors.whiteColor.withValues(alpha: 0.92),
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  Row(
                    children: [
                      _HeroMetaPill(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: context.revampedTheme.stationDetailBrandGreenLight,
                              size: 14.sp,
                            ),
                            4.horizontalSpace,
                            AppText(
                              '4.9 (124)',
                              color: context.revampedTheme.textPrimary,
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight600,
                            ),
                          ],
                        ),
                      ),
                      8.horizontalSpace,
                      _HeroMetaPill(
                        child: AppText(
                          '1.2 mi',
                          color: context.revampedTheme.textPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetaPill extends StatelessWidget {
  const _HeroMetaPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: context.revampedTheme.heroMetaPillBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _ChargerAvailabilitySection extends StatelessWidget {
  const _ChargerAvailabilitySection({
    required this.ports,
    required this.selectedPortIndex,
    required this.onPortTap,
  });

  final List<ChargerPortModel> ports;
  final int selectedPortIndex;
  final ValueChanged<int> onPortTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.revampedTheme.stationDetailContainerBackground,
      padding: EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Charger Availability',
                  color: context.revampedTheme.textPrimary,
                  fontSize: FontSizes.font18Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  color: context.revampedTheme.stationDetailBrandGreenLight,
                  shape: BoxShape.circle,
                ),
              ),
              6.horizontalSpace,
              AppText(
                'LIVE STATUS',
                color: context.revampedTheme.textSecondary,
                fontSize: FontSizes.font10Sp,
                fontWeight: FontWeights.weight600,
                letterSpacing: 1.1,
              ),
            ],
          ),
          14.verticalSpace,
          ...List.generate(ports.length, (index) {
            final uiPort = _portUiModelAt(context, index, ports[index]);
            final isSelected = ports[index].available && index == selectedPortIndex;
            return Padding(
              padding: EdgeInsets.only(bottom: index == ports.length - 1 ? 0 : 10.h),
              child: _PortAvailabilityCard(
                port: uiPort,
                isSelected: isSelected,
                onTap: ports[index].available ? () => onPortTap(index) : null,
              ),
            );
          }),
          14.verticalSpace,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: const [
              _ConnectorFilterChip(label: 'CCS'),
              _ConnectorFilterChip(label: 'TYPE 2'),
              _ConnectorFilterChip(label: 'CHADEMO'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortUiModel {
  const _PortUiModel({
    required this.id,
    required this.title,
    required this.connector,
    required this.details,
    required this.statusLabel,
    required this.available,
    required this.badgeBackground,
    required this.badgeTextColor,
    required this.statusBackground,
    required this.statusTextColor,
  });

  final String id;
  final String title;
  final String connector;
  final String details;
  final String statusLabel;
  final bool available;
  final Color badgeBackground;
  final Color badgeTextColor;
  final Color statusBackground;
  final Color statusTextColor;
}

_PortUiModel _portUiModelAt(
  BuildContext context,
  int index,
  ChargerPortModel port,
) {
  final t = context.revampedTheme;
  switch (index) {
    case 0:
      return _PortUiModel(
        id: 'P1',
        title: 'Ultra Rapid',
        connector: 'CCS',
        details: '350 kW • Station A',
        statusLabel: 'AVAILABLE',
        available: port.available,
        badgeBackground: t.mintIconBackground,
        badgeTextColor: t.availableGreen,
        statusBackground: t.mintIconBackground,
        statusTextColor: t.availableGreen,
      );
    case 1:
      return _PortUiModel(
        id: 'P2',
        title: 'Ultra Rapid',
        connector: 'CCS',
        details: '350 kW • Station B',
        statusLabel: port.available ? 'AVAILABLE' : 'IN USE (12m)',
        available: port.available,
        badgeBackground: t.mintIconBackground,
        badgeTextColor: t.availableGreen,
        statusBackground:
            port.available ? t.mintIconBackground : t.inUseBackground,
        statusTextColor: port.available ? t.availableGreen : t.inUseText,
      );
    default:
      return _PortUiModel(
        id: 'P3',
        title: 'CHAdeMO',
        connector: '',
        details: '50 kW • Station C',
        statusLabel: 'AVAILABLE',
        available: port.available,
        badgeBackground: t.portPurpleBackground,
        badgeTextColor: t.portPurpleText,
        statusBackground: t.mintIconBackground,
        statusTextColor: t.availableGreen,
      );
  }
}

class _PortAvailabilityCard extends StatelessWidget {
  const _PortAvailabilityCard({
    required this.port,
    required this.isSelected,
    required this.onTap,
  });

  final _PortUiModel port;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color:
            // isSelected
            //     ? context.revampedTheme.mintIconBackground
            //     :
            context.revampedTheme.chargerPortCardBackground,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color:
              // isSelected
              //     ? context.revampedTheme.stationDetailBrandGreen.withValues(alpha: 0.35)
              //     :
              AppColors.colorsOutlineColor.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: port.badgeBackground,
                  shape: BoxShape.circle,
                ),
                child: AppText(
                  port.id,
                  color: port.badgeTextColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      port.title,
                      color: context.revampedTheme.textPrimary,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    if (port.connector.isNotEmpty) ...[
                      2.verticalSpace,
                      AppText(
                        port.connector,
                        color: context.revampedTheme.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                    ],
                    4.verticalSpace,
                    AppText(
                      port.details,
                      color: context.revampedTheme.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: port.statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppText(
                  port.statusLabel,
                  color: port.statusTextColor,
                  fontSize: FontSizes.font10Sp,
                  fontWeight: FontWeights.weight700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectorFilterChip extends StatelessWidget {
  const _ConnectorFilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.darkGreyColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        label,
        color: context.revampedTheme.textSecondary,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: context.revampedTheme.pricingCardBackground,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Pricing',
            color: context.revampedTheme.textPrimary,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight700,
          ),
          10.verticalSpace,
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.lexend,
                fontSize: FontSizes.font28Sp,
                height: 1.2,
              ),
              children: [
                TextSpan(
                  text: 'PKR 0.42',
                  style: TextStyle(
                    color: context.revampedTheme.textPrimary,
                    fontWeight: FontWeights.weight700,
                    fontSize: FontSizes.font28Sp,
                  ),
                ),
                TextSpan(
                  text: ' /kWh',
                  style: TextStyle(
                    color: context.revampedTheme.textSecondary,
                    fontWeight: FontWeights.weight500,
                    fontSize: FontSizes.font16Sp,
                  ),
                ),
              ],
            ),
          ),
          10.verticalSpace,
          AppText(
            'Estimated cost for 80% charge: \$22.50. Dynamic pricing applies during peak hours.',
            color: context.revampedTheme.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            height: 1.45,
          ),
        ],
      ),
    );
  }
}

class _AmenitiesSection extends StatelessWidget {
  const _AmenitiesSection({required this.amenities});

  final List<AmenityModel> amenities;

  @override
  Widget build(BuildContext context) {
    final visibleAmenities = amenities.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'ON-SITE AMENITIES',
          color: context.revampedTheme.textSecondary,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight700,
          letterSpacing: 1.4,
        ),
        16.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: visibleAmenities
              .map(
                (amenity) => Expanded(
                  child: _AmenityItem(amenity: amenity),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AmenityItem extends StatelessWidget {
  const _AmenityItem({required this.amenity});

  final AmenityModel amenity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: context.revampedTheme.mintIconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            amenity.icon,
            color: context.revampedTheme.stationDetailBrandGreen,
            size: 24.sp,
          ),
        ),
        10.verticalSpace,
        AppText(
          amenity.label.toUpperCase(),
          color: context.revampedTheme.textSecondary,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight600,
          letterSpacing: 0.8,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.station});

  final HubcoLocationEntity station;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Location',
          color: context.revampedTheme.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        8.verticalSpace,
        AppText(
          'Adjacent to Green Garden Shopping Mall, Level B2 Parking.',
          color: context.revampedTheme.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight400,
          height: 1.45,
        ),
        14.verticalSpace,
        ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: SizedBox(
            height: 150.h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.revampedTheme.mapPlaceholderStart,
                        context.revampedTheme.mapPlaceholderEnd,
                      ],
                    ),
                  ),
                ),
                CustomPaint(
                  painter: _MapGridPainter(context.revampedTheme),
                  child: const SizedBox.expand(),
                ),
                Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.mapPinBlueColor.withValues(alpha: 0.85),
                    size: 28.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter(this.t);

  final AppRevampedTheme t;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = t.mapGridLine
      ..strokeWidth = 1;

    const gap = 24.0;
    for (var x = 0.0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final nodePaint = Paint()..color = t.mapGridNode;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.45), 3, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.58), 3, nodePaint);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.32), 3, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => oldDelegate.t != t;
}

class _StationDetailBottomBar extends StatelessWidget {
  const _StationDetailBottomBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.revampedTheme.stationDetailBrandGreen,
                        context.revampedTheme.stationDetailBrandGreenLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: context.revampedTheme.stationDetailBrandGreen.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppColors.transparentColor,
                    child: InkWell(
                      onTap: () => context.go('/bookings'),
                      borderRadius: BorderRadius.circular(999),
                      child: Center(
                        child: AppText(
                          'Book Slot',
                          color: AppColors.whiteColor,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            12.horizontalSpace,
            SizedBox(
              width: 54.w,
              height: 54.h,
              child: Material(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(16.r),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16.r),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: context.revampedTheme.textPrimary,
                    size: 22.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

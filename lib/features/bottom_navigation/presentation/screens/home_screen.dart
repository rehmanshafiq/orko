import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/booking/presentation/screens/book_a_slot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _center = LatLng(24.8607, 67.0011);
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#101828"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#101828"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6b7280"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#243244"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2f3f55"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2b3a"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#1f2937"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0b1220"}]}
]
''';
  static const List<({String title, String availability, String price})> _nearbyStations = [
    (title: 'HGL Liberty Market', availability: '4/6 Available', price: 'Rs 75/kWh'),
    (title: 'HGL Packages Mall', availability: '0/4 Available', price: 'Rs 80/kWh'),
    (title: 'HGL Johar Town', availability: '3/5 Available', price: 'Rs 78/kWh'),
  ];

  final Set<Marker> _markers = {
    const Marker(markerId: MarkerId('1'), position: LatLng(24.8660, 67.0082)),
    const Marker(markerId: MarkerId('2'), position: LatLng(24.8548, 67.0124)),
    const Marker(markerId: MarkerId('3'), position: LatLng(24.8512, 66.9965)),
    const Marker(markerId: MarkerId('4'), position: LatLng(24.8722, 66.9923)),
    const Marker(markerId: MarkerId('5'), position: LatLng(24.8649, 66.9854)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _center,
                zoom: 13.8,
              ),
              onMapCreated: (controller) {
                controller.setMapStyle(_darkMapStyle);
              },
              compassEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              buildingsEnabled: true,
              markers: _markers,
            ),
            SafeArea(
              child: Column(
                children: [
                  10.verticalSpace,
                  Padding(
                    padding: AppUtils.horizontal16Padding,
                    child: _buildTopActions(),
                  ),
                  const Spacer(),
                  _buildBottomSheetMock(),
                ],
              ),
            ),
            Center(
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.mapPinBlueColor,
                  border: Border.all(color: AppColors.whiteColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mapPinBlueColor.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.small(
      //   backgroundColor: AppColors.fieldBackgroundColor,
      //   onPressed: () => context.read<AuthCubit>().logout(),
      //   child: const Icon(Icons.logout, color: AppColors.whiteColor, size: 18),
      // ),
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: AppUtils.homeTopSearchPadding,
            decoration: BoxDecoration(
              color: AppColors.greyColor.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.whiteColor.withValues(alpha: 0.4), size: 22),
                8.horizontalSpace,
                Expanded(
                  child: AppText(
                    'Search stations or locations',
                    color: AppColors.whiteColor.withValues(alpha: 0.4),
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ),
                8.horizontalSpace,
                _topActionIcon(Icons.tune_rounded, isPrimary: true, isCompact: true),
              ],
            ),
          ),
        ),
        10.horizontalSpace,
        _topActionIcon(Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _topActionIcon(IconData icon, {bool isPrimary = false, bool isCompact = false}) {
    return Container(
      height: isCompact ? 30.h : 52.h,
      width: isCompact ? 30.w : 52.w,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primaryDarkColor : AppColors.greyColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isPrimary
              ? AppColors.primaryDarkColor
              : AppColors.whiteColor.withValues(alpha: 0.12),
        ),
      ),
      child: Icon(
        icon,
        size: isCompact ? 15 : 26,
        color: AppColors.whiteColor,
      ),
    );
  }

  Widget _buildBottomSheetMock() {
    return Container(
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: AppColors.blackColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Container(
              height: 3.h,
              width: 26.w,
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          12.verticalSpace,
          AppText(
            'Nearby Stations',
            color: AppColors.whiteColor,
            fontSize: FontSizes.font24Sp,
            fontWeight: FontWeights.weight700,
          ),
          10.verticalSpace,
          Row(
            children: [
              _chip('Available Now', isActive: true),
              8.horizontalSpace,
              _chip('DC Fast'),
              8.horizontalSpace,
              _chip('AC Level 2'),
            ],
          ),
          12.verticalSpace,
          SizedBox(
            height: 92.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyStations.length,
              separatorBuilder: (_, __) => 8.horizontalSpace,
              itemBuilder: (context, index) {
                final station = _nearbyStations[index];
                return SizedBox(
                  width: 156.w,
                  child: _stationCard(
                    context,
                    station.title,
                    station.availability,
                    station.price,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool isActive = false}) {
    return Container(
      padding: AppUtils.homeFilterChipPadding,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryDarkColor.withValues(alpha: 0.22) : AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? AppColors.primaryDarkColor : AppColors.whiteColor.withValues(alpha: 0.12),
        ),
      ),
      child: AppText(
        text,
        color: isActive ? AppColors.primaryDarkColor : AppColors.whiteColor.withValues(alpha: 0.8),
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }

  Widget _stationCard(
    BuildContext context,
    String title,
    String availability,
    String price,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BookASlotScreen(),
          ),
        );
      },
      child: Container(
        padding: AppUtils.homeStationCardPadding,
        decoration: BoxDecoration(
          color: AppColors.fieldBackgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              title,
              color: AppColors.whiteColor,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            4.verticalSpace,
            AppText(
              availability,
              color: AppColors.primaryDarkColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight500,
            ),
            6.verticalSpace,
            AppText(
              price,
              color: AppColors.whiteColor.withValues(alpha: 0.75),
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      ),
    );
  }
}

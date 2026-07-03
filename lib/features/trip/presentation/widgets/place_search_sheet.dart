import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/services/google_places_service.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Opens a Google Places autocomplete sheet and resolves the picked place to
/// coordinates. Returns `null` if the user dismisses without selecting.
Future<PlaceLocation?> showPlaceSearchSheet(
  BuildContext context, {
  required String title,
  bool showCurrentLocation = false,
}) {
  return showModalBottomSheet<PlaceLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceSearchSheet(
      title: title,
      showCurrentLocation: showCurrentLocation,
    ),
  );
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({
    required this.title,
    this.showCurrentLocation = false,
  });

  final String title;

  /// When true, shows the "Use my current location" affordance (only the Start
  /// field opts in).
  final bool showCurrentLocation;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final GooglePlacesService _places = GooglePlacesService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Groups autocomplete + details calls for one search session (billing).
  final String _sessionToken =
      DateTime.now().microsecondsSinceEpoch.toString();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _resolving = false;

  /// True while resolving the device GPS + reverse geocoding for the
  /// "Use my current location" action.
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final results =
        await _places.autocomplete(value, sessionToken: _sessionToken);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _searching = false;
    });
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    setState(() => _resolving = true);
    final place =
        await _places.details(suggestion.placeId, sessionToken: _sessionToken);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (place != null) {
      Navigator.of(context).pop(place);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t load that location. Try again.')),
      );
    }
  }

  /// Resolves the device's current position, reverse-geocodes it to a readable
  /// address, and returns it as the picked place. Handles disabled location
  /// services and denied permissions with a snackbar.
  Future<void> _useCurrentLocation() async {
    if (_locating || _resolving) return;

    final messenger = ScaffoldMessenger.of(context);
    void fail(String message) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      fail('Turn on location services to use your current location.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      fail('Location permission is required to use your current location.');
      return;
    }

    setState(() => _locating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      // Prefer a readable address; fall back to the raw coordinates so trip
      // planning still has a usable point even if geocoding fails.
      final place =
          await _places.reverseGeocode(position.latitude, position.longitude) ??
              PlaceLocation(
                name: 'My Current Location',
                address: '',
                latitude: position.latitude,
                longitude: position.longitude,
              );
      if (!mounted) return;
      Navigator.of(context).pop(place);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      fail('Could not get your current location. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets.bottom;

    // Keep the sheet at a fixed 75% of the screen. Lift it by the keyboard
    // inset so its content clears the keyboard, but never lift it so far that
    // its top would slide under the status bar — cap the lift accordingly
    // (when it can't lift fully, the keyboard simply overlaps the bottom and
    // the results list scrolls).
    final sheetHeight = 0.45.sh;
    final maxLift =
        (media.size.height - media.padding.top - 8.h - sheetHeight)
            .clamp(0.0, double.infinity);
    final bottomLift = viewInsets.clamp(0.0, maxLift);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomLift),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: ui.scaffoldBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            12.verticalSpace,
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ui.borderSubtle,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: Column(
                children: [
                  12.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          widget.title,
                          color: ui.textPrimary,
                          fontSize: FontSizes.font16Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22.sp,
                          color: ui.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  Container(
                    padding: AppUtils.vertical10Horizontal12Padding,
                    decoration: BoxDecoration(
                      color: ui.searchBackground,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: ui.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded,
                            size: 18.sp, color: ui.brandPrimary),
                        8.horizontalSpace,
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.search,
                            onChanged: _onChanged,
                            style: TextStyle(
                              color: ui.textPrimary,
                              fontSize: FontSizes.font14Sp,
                              fontWeight: FontWeights.weight500,
                            ),
                            cursorColor: ui.brandPrimary,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'Search city, area or address',
                              hintStyle: TextStyle(
                                color: ui.textPrimary.withValues(alpha: 0.4),
                                fontSize: FontSizes.font14Sp,
                              ),
                            ),
                          ),
                        ),
                        if (_searching)
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ui.brandPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.showCurrentLocation) ...[
                    10.verticalSpace,
                    _currentLocationTile(ui),
                  ],
                ],
              ),
            ),
            8.verticalSpace,
            Expanded(child: _buildResults(ui)),
          ],
        ),
      ),
    );
  }

  /// "Use my current location" row shown directly below the search field —
  /// mirrors the Google Maps affordance.
  Widget _currentLocationTile(AppUiColors ui) {
    return InkWell(
      onTap: _locating ? null : _useCurrentLocation,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: _locating
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ui.brandPrimary,
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 18.sp,
                      color: ui.brandPrimary,
                    ),
            ),
            10.horizontalSpace,
            AppText(
              _locating ? 'Getting your location…' : 'Use my current location',
              color: ui.brandPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(AppUiColors ui) {
    if (_resolving) {
      return Center(
        child: CircularProgressIndicator(color: ui.brandPrimary),
      );
    }
    if (_controller.text.trim().isEmpty) {
      return Center(
        child: AppText(
          'Start typing to search locations',
          color: ui.textPrimary.withValues(alpha: 0.5),
          fontSize: FontSizes.font12Sp,
        ),
      );
    }
    if (!_searching && _suggestions.isEmpty) {
      return Center(
        child: AppText(
          'No matching locations',
          color: ui.textPrimary.withValues(alpha: 0.5),
          fontSize: FontSizes.font12Sp,
        ),
      );
    }
    return ListView.separated(
      padding: AppUtils.horizontal16Padding,
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: ui.borderSubtle.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        final s = _suggestions[index];
        return InkWell(
          onTap: () => _select(s),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18.sp, color: ui.brandPrimary),
                10.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        s.primaryText,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                      if (s.secondaryText.isNotEmpty) ...[
                        2.verticalSpace,
                        AppText(
                          s.secondaryText,
                          color: ui.textPrimary.withValues(alpha: 0.6),
                          fontSize: FontSizes.font12Sp,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

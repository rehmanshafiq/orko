import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/trip/domain/entities/place_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/get_place_details_usecase.dart';
import 'package:orko_hubco/features/trip/domain/usecases/place_search_params.dart';
import 'package:orko_hubco/features/trip/domain/usecases/search_places_usecase.dart';
import 'package:uuid/uuid.dart';

/// Opens the place search sheet (backed by the Hubco Places API) and resolves
/// the picked place to coordinates. Returns `null` if the user dismisses
/// without selecting.
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
  final SearchPlacesUseCase _searchPlaces = sl<SearchPlacesUseCase>();
  final GetPlaceDetailsUseCase _getPlaceDetails = sl<GetPlaceDetailsUseCase>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const String _components = 'country:pk';

  /// Bias results to ~50 km around the user's last known position.
  static const int _biasRadiusMeters = PlaceAutocompleteParams.maxRadius;

  /// 422 messages that a retry can't fix.
  static const Set<String> _nonRetryableMessages = {
    'input is required.',
    'place_id is required.',
    'Place not found.',
    'Google Places is not configured.',
  };

  /// Places endpoints require auth; guests get a login prompt instead.
  final bool _isGuest = AppStorage.isGuest;

  /// Groups every autocomplete call of one search with its details call. A
  /// new token starts after each details call.
  String _sessionToken = const Uuid().v4();

  /// Bumped on every keystroke/retry; a response is applied only if it still
  /// belongs to the latest query, so out-of-order replies are dropped.
  int _querySeq = 0;

  /// Last known device position (only if permission was already granted),
  /// used as an optional location bias.
  Position? _bias;

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  String? _searchError;
  bool _searchErrorRetryable = false;
  bool _resolving = false;

  /// Shown when resolving a picked suggestion fails; the sheet stays open so
  /// the user can tap again or pick another place.
  String? _detailsError;

  /// True while resolving the device GPS for the "Use my current location"
  /// action.
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    if (!_isGuest) _loadLocationBias();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Never prompts for permission — the bias is a nice-to-have.
  Future<void> _loadLocationBias() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
      final position = await Geolocator.getLastKnownPosition();
      if (mounted) _bias = position;
    } catch (_) {
      // Search simply runs unbiased.
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    final seq = ++_querySeq;
    if (_isGuest) return;
    if (query.isEmpty) {
      setState(() {
        _suggestions = const [];
        _searching = false;
        _searchError = null;
        _detailsError = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
      _detailsError = null;
    });
    _debounce = Timer(_debounceDelay, () => _search(query, seq));
  }

  void _retrySearch() {
    final query = _controller.text.trim();
    if (query.isEmpty || _isGuest) return;
    _debounce?.cancel();
    final seq = ++_querySeq;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    _search(query, seq);
  }

  Future<void> _search(String query, int seq) async {
    final result = await _searchPlaces(
      PlaceAutocompleteParams(
        input: query,
        sessionToken: _sessionToken,
        latitude: _bias?.latitude,
        longitude: _bias?.longitude,
        radius: _biasRadiusMeters,
        components: _components,
      ),
    );
    if (!mounted || seq != _querySeq) return;
    result.fold(
      (failure) => setState(() {
        _suggestions = const [];
        _searching = false;
        _searchError = _messageFor(failure);
        _searchErrorRetryable = _isRetryable(failure);
      }),
      (suggestions) => setState(() {
        _suggestions = suggestions;
        _searching = false;
        _searchError = null;
      }),
    );
  }

  Future<void> _select(PlaceSuggestion suggestion) async {
    if (_resolving || _locating) return;
    setState(() {
      _resolving = true;
      _detailsError = null;
    });
    final result = await _getPlaceDetails(
      PlaceDetailsParams(
        placeId: suggestion.placeId,
        sessionToken: _sessionToken,
      ),
    );
    // The details call closes the session; any further search starts anew.
    _sessionToken = const Uuid().v4();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _resolving = false;
        _detailsError = _messageFor(failure);
      }),
      (place) => Navigator.of(context).pop(place),
    );
  }

  String _messageFor(Failure failure) {
    if (failure is NetworkFailure) {
      return 'No internet connection. Check your connection and try again.';
    }
    final message = failure.message.trim();
    return message.isEmpty ? 'Request Failed' : message;
  }

  bool _isRetryable(Failure failure) {
    if (failure is UnauthorizedFailure) return false;
    final code = failure.statusCode;
    if (code == 401 || code == 403) return false;
    return !_nonRetryableMessages.contains(failure.message.trim());
  }

  void _promptLogin() {
    AuthRequiredDialog.show(
      context,
      feature: 'trip',
      message:
          'You\'re browsing as a guest. Please log in or create an account to search locations.',
    );
  }

  /// Resolves the device's current position and returns it as the picked
  /// place. Handles disabled location services and denied permissions with a
  /// snackbar.
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
      if (!mounted) return;
      // The app no longer calls Google geocoding directly (no client-side
      // key), so the point is labelled generically; trip planning only needs
      // the coordinates.
      Navigator.of(context).pop(
        PlaceLocation(
          name: 'My Current Location',
          address: '',
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
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
                            readOnly: _resolving,
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
                  if (_detailsError != null) ...[
                    8.verticalSpace,
                    _detailsErrorBanner(_detailsError!),
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
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
        ),
      ),
    );
  }

  /// Centered message with an optional action (retry / log in).
  Widget _messageState(
    AppUiColors ui,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: AppUtils.horizontal16Padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              message,
              color: ui.textPrimary.withValues(alpha: 0.5),
              fontSize: FontSizes.font12Sp,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              8.verticalSpace,
              TextButton(
                onPressed: onAction,
                child: AppText(
                  actionLabel,
                  color: ui.brandPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailsErrorBanner(String message) {
    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16.sp,
          color: AppColors.removeColor,
        ),
        6.horizontalSpace,
        Expanded(
          child: AppText(
            message,
            color: AppColors.removeColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
      ],
    );
  }

  Widget _buildResults(AppUiColors ui) {
    if (_resolving) {
      return Center(
        child: CircularProgressIndicator(color: ui.brandPrimary),
      );
    }
    if (_isGuest) {
      return _messageState(
        ui,
        'Log in or create an account to search locations',
        actionLabel: 'Log in',
        onAction: _promptLogin,
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
    if (_searchError != null) {
      return _messageState(
        ui,
        _searchError!,
        actionLabel: _searchErrorRetryable ? 'Retry' : null,
        onAction: _searchErrorRetryable ? _retrySearch : null,
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

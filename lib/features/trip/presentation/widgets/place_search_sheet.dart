import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
}) {
  return showModalBottomSheet<PlaceLocation>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceSearchSheet(title: title),
  );
}

class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.title});

  final String title;

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

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        height: 0.75.sh,
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

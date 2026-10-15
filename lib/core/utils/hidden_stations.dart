/// Stations that must never be shown anywhere in the app (map, nearby list,
/// filters, search, popular, Android Auto / CarPlay).
///
/// Filtered at the data-source level so every consumer is covered at once.
/// Matching is case-insensitive on a name fragment, so branch suffixes such as
/// "METRO Safari Store Gulshan-e-Iqbal" are caught too.
class HiddenStations {
  HiddenStations._();

  static const List<String> _hiddenNameFragments = <String>[
    'metro safari store',
  ];

  /// True when a station with this [name] / [displayName] should be hidden.
  static bool isHidden(String name, [String displayName = '']) {
    final haystack = '$name $displayName'.toLowerCase();
    return _hiddenNameFragments.any(haystack.contains);
  }
}

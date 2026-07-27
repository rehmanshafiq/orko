import 'dart:async';
import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/add_recent_search_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/clear_recent_searches_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/get_popular_stations_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/get_recent_searches_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/remove_recent_search_usecase.dart';
import 'package:orko_hubco/features/search/domain/usecases/search_stations_usecase.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchStationsUseCase _searchStationsUseCase;
  final GetPopularStationsUseCase _getPopularStationsUseCase;
  final GetRecentSearchesUseCase _getRecentSearchesUseCase;
  final AddRecentSearchUseCase _addRecentSearchUseCase;
  final RemoveRecentSearchUseCase _removeRecentSearchUseCase;
  final ClearRecentSearchesUseCase _clearRecentSearchesUseCase;

  SearchCubit({
    required SearchStationsUseCase searchStationsUseCase,
    required GetPopularStationsUseCase getPopularStationsUseCase,
    required GetRecentSearchesUseCase getRecentSearchesUseCase,
    required AddRecentSearchUseCase addRecentSearchUseCase,
    required RemoveRecentSearchUseCase removeRecentSearchUseCase,
    required ClearRecentSearchesUseCase clearRecentSearchesUseCase,
  })  : _searchStationsUseCase = searchStationsUseCase,
        _getPopularStationsUseCase = getPopularStationsUseCase,
        _getRecentSearchesUseCase = getRecentSearchesUseCase,
        _addRecentSearchUseCase = addRecentSearchUseCase,
        _removeRecentSearchUseCase = removeRecentSearchUseCase,
        _clearRecentSearchesUseCase = clearRecentSearchesUseCase,
        super(const SearchState());

  final TextEditingController searchController = TextEditingController();

  /// Default coordinates (Karachi) used when the device location is unavailable.
  static const double _defaultLatitude = 24.8607;
  static const double _defaultLongitude = 67.0011;

  /// Debounce window so we don't fire a request on every keystroke.
  static const Duration _debounce = Duration(milliseconds: 400);

  Timer? _debounceTimer;
  double? _latitude;
  double? _longitude;

  /// Tracks the latest query so a slow earlier response can't overwrite the
  /// results of a newer one (out-of-order completion).
  int _requestSeq = 0;

  /// Loads recent searches + popular stations. Resolves device location first
  /// (best-effort) so distances are correct; falls back to a default location.
  Future<void> init() async {
    await _loadRecentSearches();
    await _resolveLocation();
    await _loadPopular();
  }

  Future<void> _resolveLocation() async {
    final position = await _resolveCurrentPosition();
    _latitude = position?.latitude ?? _defaultLatitude;
    _longitude = position?.longitude ?? _defaultLongitude;
  }

  Future<void> _loadPopular() async {
    if (isClosed) return;
    emit(state.copyWith(popularStatus: SearchStatus.loading, popularError: ''));
    final result = await _getPopularStationsUseCase(
      PopularStationsParams(
        latitude: _latitude ?? _defaultLatitude,
        longitude: _longitude ?? _defaultLongitude,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        popularStatus: SearchStatus.failure,
        popularError: failure.message,
      )),
      (stations) => emit(state.copyWith(
        popularStatus: SearchStatus.success,
        popularStations: stations,
      )),
    );
  }

  Future<void> _loadRecentSearches() async {
    final result = await _getRecentSearchesUseCase(const NoParams());
    if (isClosed) return;
    result.fold(
      (_) {}, // A local-storage read failure shouldn't block the screen.
      (recents) => emit(state.copyWith(recentSearches: recents)),
    );
  }

  /// Retries loading popular stations (e.g. from an error-state "Retry" button).
  Future<void> retryPopular() => _loadPopular();

  /// Called as the user types. Debounces, then searches; an empty query
  /// returns the screen to its idle (recent + popular) layout.
  void onQueryChanged(String value) {
    final trimmed = value.trim();
    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      _requestSeq++; // Invalidate any in-flight search.
      emit(state.copyWith(
        query: '',
        resultsStatus: SearchStatus.initial,
        results: const [],
        resultsError: '',
      ));
      return;
    }

    emit(state.copyWith(query: trimmed));
    _debounceTimer = Timer(_debounce, () => _runSearch(trimmed));
  }

  /// Submits the current query immediately (keyboard "search" action). Persists
  /// it to recent history.
  Future<void> submitSearch() async {
    _debounceTimer?.cancel();
    final query = searchController.text.trim();
    if (query.isEmpty) return;
    await _persistRecent(query);
    await _runSearch(query);
  }

  /// Re-runs a previous search when the user taps a recent item.
  Future<void> searchFromRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _debounceTimer?.cancel();
    searchController.text = trimmed;
    emit(state.copyWith(query: trimmed));
    await _persistRecent(trimmed);
    await _runSearch(trimmed);
  }

  /// Persists the query that produced a result the user tapped into. Fire and
  /// forget — navigation shouldn't wait on a local write.
  void recordResultTap(String query) {
    unawaited(_persistRecent(query));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_requestSeq;
    if (isClosed) return;
    emit(state.copyWith(
      query: query,
      resultsStatus: SearchStatus.loading,
      resultsError: '',
    ));

    final result = await _searchStationsUseCase(
      SearchStationsParams(
        query: query,
        latitude: _latitude ?? _defaultLatitude,
        longitude: _longitude ?? _defaultLongitude,
      ),
    );

    // A newer query (or a clear) superseded this request — drop the result.
    if (isClosed || seq != _requestSeq) return;
    result.fold(
      (failure) => emit(state.copyWith(
        resultsStatus: SearchStatus.failure,
        resultsError: failure.message,
      )),
      (stations) => emit(state.copyWith(
        resultsStatus: SearchStatus.success,
        results: stations,
      )),
    );
  }

  Future<void> _persistRecent(String query) async {
    final result = await _addRecentSearchUseCase(query);
    if (isClosed) return;
    result.fold(
      (_) {},
      (recents) => emit(state.copyWith(recentSearches: recents)),
    );
  }

  Future<void> removeRecentSearch(String query) async {
    final result = await _removeRecentSearchUseCase(query);
    if (isClosed) return;
    result.fold(
      (_) {},
      (recents) => emit(state.copyWith(recentSearches: recents)),
    );
  }

  Future<void> clearRecentSearches() async {
    final result = await _clearRecentSearchesUseCase(const NoParams());
    if (isClosed) return;
    result.fold(
      (_) {},
      (_) => emit(state.copyWith(recentSearches: const [])),
    );
  }

  /// Clears the text field and returns to the idle layout.
  void clearSearch() {
    searchController.clear();
    onQueryChanged('');
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      AppLogger.d('[Search] Failed to resolve current position: $e');
      return null;
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    searchController.dispose();
    return super.close();
  }
}

import 'package:equatable/equatable.dart';

/// A query the user previously searched for, persisted to local storage so the
/// Search screen can show recent history. Newest first, de-duplicated by
/// [query] (case-insensitive).
class RecentSearchEntity extends Equatable {
  const RecentSearchEntity({
    required this.query,
    required this.searchedAt,
  });

  final String query;
  final DateTime searchedAt;

  @override
  List<Object?> get props => [query, searchedAt];
}

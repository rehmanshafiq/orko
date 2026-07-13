import 'package:equatable/equatable.dart';

/// A support-ticket category option from
/// `GET api/v1/cvp/cvp-support-ticket/categories/`.
///
/// [value] is the backend DB value (snake_case) sent as `category`; [label] is
/// what the user sees. The list is backend-driven — adding/removing a category
/// is a server-only change.
class SupportCategoryEntity extends Equatable {
  const SupportCategoryEntity({required this.value, required this.label});

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

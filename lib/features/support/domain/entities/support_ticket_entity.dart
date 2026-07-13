import 'package:equatable/equatable.dart';

/// A support ticket created via `POST api/v1/cvp/cvp-support-ticket/`.
///
/// On success the backend returns an auto-generated [referenceCode] the user
/// can quote when following up.
class SupportTicketEntity extends Equatable {
  const SupportTicketEntity({
    required this.referenceCode,
    this.id,
    this.category,
    this.description,
    this.status,
  });

  final String referenceCode;
  final int? id;
  final String? category;
  final String? description;
  final String? status;

  @override
  List<Object?> get props => [referenceCode, id, category, description, status];
}

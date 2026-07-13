import 'package:orko_hubco/features/support/domain/entities/support_ticket_entity.dart';

/// Data model for a support ticket parsed from the response envelope's `body`.
class SupportTicketModel extends SupportTicketEntity {
  const SupportTicketModel({
    required super.referenceCode,
    super.id,
    super.category,
    super.description,
    super.status,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      referenceCode: (json['reference_code'] ?? '').toString(),
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}'),
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

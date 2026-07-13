import 'package:orko_hubco/features/support/domain/entities/support_category_entity.dart';

/// Data model for a category option parsed from the categories endpoint's
/// `body` list (`{ "value": ..., "label": ... }`).
class SupportCategoryModel extends SupportCategoryEntity {
  const SupportCategoryModel({required super.value, required super.label});

  factory SupportCategoryModel.fromJson(Map<String, dynamic> json) {
    final value = (json['value'] ?? '').toString();
    final label = (json['label'] ?? '').toString();
    return SupportCategoryModel(
      value: value,
      // Fall back to the raw value if the backend omits a label.
      label: label.isEmpty ? value : label,
    );
  }
}

import 'package:orko_hubco/features/charging/domain/entities/station_reviews_entity.dart';

/// Parses a single review object from the reviews API.
class StationReviewModel extends StationReviewItemEntity {
  const StationReviewModel({
    required super.id,
    required super.locationId,
    required super.customerId,
    required super.customerName,
    required super.rating,
    required super.description,
    super.customerProfilePicture,
    super.createdAt,
    super.isCurrentUser,
  });

  factory StationReviewModel.fromJson(Map<String, dynamic> json) {
    return StationReviewModel(
      id: _asInt(json['id']),
      locationId: _asInt(json['location_id']),
      customerId: _asInt(json['customer_id']),
      customerName: (json['customer_name'] as Object?)?.toString() ?? '',
      customerProfilePicture: _asNullableString(
        json['customer_profile_picture'],
      ),
      rating: _asInt(json['rating']),
      description: (json['description'] as Object?)?.toString() ?? '',
      createdAt: (json['created_at'] as Object?)?.toString() ?? '',
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}

/// Parses the `review_status` percentages block.
class ReviewStatusModel extends ReviewStatusEntity {
  const ReviewStatusModel({
    super.belowAverage,
    super.average,
    super.good,
    super.excellent,
  });

  factory ReviewStatusModel.fromJson(Map<String, dynamic> json) {
    return ReviewStatusModel(
      belowAverage: _asDouble(json['below_average']),
      average: _asDouble(json['average']),
      good: _asDouble(json['good']),
      excellent: _asDouble(json['excellent']),
    );
  }
}

/// Parses the full `body` of the GET reviews response.
class StationReviewsModel extends StationReviewsEntity {
  const StationReviewsModel({
    super.reviews,
    super.reviewStatus,
    super.totalCount,
    super.averageRating,
  });

  factory StationReviewsModel.fromJson(Map<String, dynamic> body) {
    final rawReviews = body['reviews'];
    final reviews = rawReviews is List
        ? rawReviews
            .whereType<Map>()
            .map((e) =>
                StationReviewModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : const <StationReviewModel>[];

    final rawStatus = body['review_status'];
    final status = rawStatus is Map
        ? ReviewStatusModel.fromJson(Map<String, dynamic>.from(rawStatus))
        : const ReviewStatusModel();

    return StationReviewsModel(
      reviews: reviews,
      reviewStatus: status,
      totalCount: _asInt(body['total_count']),
      averageRating: _asDouble(body['average_rating']),
    );
  }
}

// ── Lenient JSON coercers ─────────────────────────────────────────────────
// The API can send numbers as int, double, or numeric strings; coerce safely.

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0;
  return 0;
}

String? _asNullableString(Object? value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';

/// Maps the `api/v1/charging-station/{id}` response (the `body.station` object)
/// into a [ChargingStationDetailEntity]. Every field is parsed defensively so a
/// missing or malformed key can never throw.
class ChargingStationDetailModel extends ChargingStationDetailEntity {
  const ChargingStationDetailModel({
    required super.locationId,
    required super.name,
    required super.status,
    required super.address,
    required super.contactNumber,
    required super.openingTime,
    required super.closingTime,
    required super.distance,
    required super.latitude,
    required super.longitude,
    required super.amenities,
    required super.chargers,
    required super.averageRating,
    required super.totalReviews,
    required super.reviews,
    super.addressGuide,
    super.isClosed,
    super.bannerImage,
  });

  factory ChargingStationDetailModel.fromJson(Map<String, dynamic> json) {
    final location = _asMap(json['location']);
    final reviewDetails = _asMap(json['review_details']);

    return ChargingStationDetailModel(
      locationId: (json['location_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      status: json['status'] == true,
      isClosed: json['is_closed'] == true,
      bannerImage: _asNullableUrl(json['banner_image']),
      address: (json['address'] ?? '').toString(),
      addressGuide: json['address_guide']?.toString(),
      contactNumber: (json['contact_number'] ?? '').toString(),
      openingTime: (json['opening_time'] ?? '').toString(),
      closingTime: (json['closing_time'] ?? '').toString(),
      distance: _asDouble(json['distance']),
      latitude: _asDouble(location['lat']),
      longitude: _asDouble(location['long']),
      amenities: _asList(json['amenities'])
          .map(_amenityFromJson)
          .toList(growable: false),
      chargers: _asList(json['chargers'])
          .map(_chargerFromJson)
          .toList(growable: false),
      averageRating: _asDouble(reviewDetails['average_rating']),
      totalReviews: _asInt(reviewDetails['total_reviews']),
      reviews: _asList(reviewDetails['reviews'])
          .map(_reviewFromJson)
          .toList(growable: false),
    );
  }

  static AmenityEntity _amenityFromJson(Map<String, dynamic> json) {
    return AmenityEntity(
      name: (json['name'] ?? '').toString(),
      imageUrl: (json['image'] ?? '').toString(),
    );
  }

  /// Amenity icons from the detail API are imgix assets; this applies a
  /// monochrome tint so glyphs read black in light mode and white in dark mode.
  static String themedAmenityImageUrl(String imageUrl, {required bool isLight}) {
    if (imageUrl.isEmpty) return imageUrl;

    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return imageUrl;

    final host = uri.host.toLowerCase();
    if (!host.contains('imgix.net')) return imageUrl;

    final monochrome = isLight ? '000000' : 'FFFFFF';
    final params = Map<String, String>.from(uri.queryParameters);
    params['monochrome'] = monochrome;
    return uri.replace(queryParameters: params).toString();
  }

  static ChargerEntity _chargerFromJson(Map<String, dynamic> json) {
    final rawChargePointId =
        (json['charge_point_id'] ?? json['charge_point'] ?? '')
            .toString()
            .trim();
    return ChargerEntity(
      id: _asInt(json['id']),
      chargePointId: rawChargePointId.isEmpty ? null : rawChargePointId,
      model: (json['model'] ?? '').toString(),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      type: json['type']?.toString(),
      connectivityStatus: json['connectivity_status']?.toString(),
      status: json['status'] == true,
      connectors: _asList(json['connectors'])
          .map(_connectorFromJson)
          .toList(growable: false),
    );
  }

  static ConnectorEntity _connectorFromJson(Map<String, dynamic> json) {
    final price = json['price'];
    return ConnectorEntity(
      id: _asInt(json['id']),
      connectorId: json['connector_id'] == null
          ? null
          : _asInt(json['connector_id']),
      connectorType: (json['connector_type'] ?? '').toString(),
      connectorFormat: (json['connector_format'] ?? '').toString(),
      powerType: (json['power_type'] ?? '').toString(),
      power: (json['power'] ?? '').toString(),
      connectorState: (json['connector_state'] ?? '').toString(),
      price: price is Map ? _priceFromJson(_asMap(price)) : null,
    );
  }

  static ConnectorPriceEntity _priceFromJson(Map<String, dynamic> json) {
    return ConnectorPriceEntity(
      pricingMode: (json['pricing_mode'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      price: _asDouble(json['price']),
    );
  }

  static StationReviewEntity _reviewFromJson(Map<String, dynamic> json) {
    return StationReviewEntity(
      name: (json['customer_name'] ?? json['name'] ?? json['user_name'] ?? '')
          .toString(),
      text:
          (json['description'] ?? json['comment'] ?? json['text'] ?? json['review'] ?? '')
              .toString(),
      rating: _asDouble(json['rating']),
      createdAt: (json['created_at'] ?? '').toString(),
      profilePicture: json['customer_profile_picture']?.toString(),
      isCurrentUser: json['is_current_user'] == true,
    );
  }

  // ── Safe coercion helpers ───────────────────────────────────────────────

  /// Null when the value is absent or blank, so callers can fall back to the
  /// bundled asset.
  static String? _asNullableUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    return url.isEmpty ? null : url;
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

import 'package:orko_hubco/features/booking/domain/entities/verify_qr_result_entity.dart';

/// Maps the `{status, message, body}` envelope from `POST api/v1/bookings/
/// verify-qr/` into a [VerifyQrResultEntity]. Parsed defensively — the same
/// shape is returned for both the `200` (match) and `422` (mismatch) responses.
class VerifyQrModel extends VerifyQrResultEntity {
  const VerifyQrModel({
    required super.isMatch,
    super.bookedChargePointId,
    super.bookedConnectorId,
    super.message,
  });

  /// Builds from the full response envelope so the human-readable `message`
  /// (which lives at the envelope level) is preserved alongside the `body`.
  factory VerifyQrModel.fromEnvelope(Map<String, dynamic> envelope) {
    final body = envelope['body'] is Map
        ? Map<String, dynamic>.from(envelope['body'] as Map)
        : const <String, dynamic>{};

    return VerifyQrModel(
      isMatch: body['is_match'] == true,
      bookedChargePointId: _asStringOrNull(body['booked_charge_point_id']),
      bookedConnectorId: _asIntOrNull(body['booked_connector_id']),
      message: _asStringOrNull(body['message']) ??
          _asStringOrNull(envelope['message']),
    );
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _asStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }
}

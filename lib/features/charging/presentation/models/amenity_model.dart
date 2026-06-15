import 'package:flutter/material.dart';

/// Amenity chip data. Prefers a remote [imageUrl] when present, otherwise falls
/// back to a local [icon].
class AmenityModel {
  const AmenityModel({
    required this.label,
    this.icon,
    this.imageUrl,
  });

  final String label;
  final IconData? icon;
  final String? imageUrl;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

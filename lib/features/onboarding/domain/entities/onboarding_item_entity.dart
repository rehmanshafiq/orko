import 'package:equatable/equatable.dart';

class OnboardingItemEntity extends Equatable {
  const OnboardingItemEntity({
    required this.imagePath,
    required this.title,
    this.titleHighlight = '',
    required this.description,
  });

  final String imagePath;

  /// Leading, regular-weight portion of the headline (e.g. "Locate a ").
  final String title;

  /// Trailing, bold-weight portion of the headline (e.g. "Charger").
  final String titleHighlight;

  final String description;

  @override
  List<Object?> get props => [imagePath, title, titleHighlight, description];
}

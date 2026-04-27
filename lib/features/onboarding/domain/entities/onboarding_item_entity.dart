import 'package:equatable/equatable.dart';

class OnboardingItemEntity extends Equatable {
  const OnboardingItemEntity({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;

  @override
  List<Object?> get props => [imagePath, title, description];
}

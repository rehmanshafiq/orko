class ReviewModel {
  const ReviewModel({
    required this.name,
    required this.text,
    required this.rating,
    this.createdAt = '',
    this.profilePicture,
    this.isCurrentUser = false,
  });

  final String name;

  /// Review body, shown to the user (maps to the API `description` key).
  final String text;
  final double rating;
  final String createdAt;
  final String? profilePicture;
  final bool isCurrentUser;
}

/// Pure domain entity representing a trip rating and review.
class RideRating {
  final String? id;
  final String rideId;
  final int rating;
  final String? review;
  final List<String> tags;
  final DateTime? createdAt;

  const RideRating({
    this.id,
    required this.rideId,
    required this.rating,
    this.review,
    this.tags = const [],
    this.createdAt,
  });
}

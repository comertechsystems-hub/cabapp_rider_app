import '../../domain/entities/rating.dart';

class RatingModel extends RideRating {
  const RatingModel({
    super.id,
    required super.rideId,
    required super.rating,
    super.review,
    super.tags = const [],
    super.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    } else if (json['tags'] is String && (json['tags'] as String).isNotEmpty) {
      parsedTags = (json['tags'] as String).split(',').map((e) => e.trim()).toList();
    }

    return RatingModel(
      id: json['name'] ?? json['id'],
      rideId: json['ride'] ?? json['ride_id'] ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      review: json['review'],
      tags: parsedTags,
      createdAt: json['creation'] != null ? DateTime.tryParse(json['creation']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ride': rideId,
        'rating': rating,
        'review': review,
        'tags': tags,
        'creation': createdAt?.toIso8601String(),
      };
}

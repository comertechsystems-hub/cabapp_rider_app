import '../entities/rating.dart';

abstract class IRatingsRepository {
  Future<RideRating> submitRating({
    required String rideId,
    required int rating,
    String? review,
    List<String>? tags,
  });

  Future<List<RideRating>> getUserRatings();
}

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/i_ratings_repository.dart';
import '../models/rating_model.dart';

class RatingsRepository implements IRatingsRepository {
  final IApiClient apiClient;

  RatingsRepository({required this.apiClient});

  @override
  Future<RideRating> submitRating({
    required String rideId,
    required int rating,
    String? review,
    List<String>? tags,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.submitRating,
      body: {
        'ride_id': rideId,
        'rating': rating,
        'review': ?review,
        'tags': tags != null && tags.isNotEmpty ? tags.join(',') : null,
      },
    );
    final data = res['data'] ?? res['rating'] ?? res;
    return RatingModel.fromJson(data);
  }

  @override
  Future<List<RideRating>> getUserRatings() async {
    final res = await apiClient.get(ApiEndpoints.getUserRatings);
    final List<dynamic> list = res is List
        ? res
        : (res['data'] is List ? res['data'] : (res['ratings'] is List ? res['ratings'] : []));
    return list.map((item) => RatingModel.fromJson(item)).toList();
  }
}

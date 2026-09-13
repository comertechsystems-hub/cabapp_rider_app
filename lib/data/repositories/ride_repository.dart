import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/fare_estimate_model.dart';
import '../models/ride_model.dart';

class RideRepository {
  final ApiClient apiClient;

  RideRepository({required this.apiClient});

  Future<List<FareEstimateModel>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.getFareEstimatesAll,
      body: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
      },
    );

    final List<dynamic> list = res is List ? res : (res['data'] ?? []);
    return list.map((item) => FareEstimateModel.fromJson(item)).toList();
  }

  Future<RideModel> requestRide({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required String vehicleCategory,
    bool autoSearch = true,
  }) async {
    final res = await apiClient.post(
      ApiEndpoints.requestRide,
      body: {
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_address': destinationAddress,
        'destination_lat': destinationLat,
        'destination_lng': destinationLng,
        'vehicle_category': vehicleCategory,
        'auto_search': autoSearch ? 1 : 0,
      },
    );

    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  Future<RideModel> getRide(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.getRide,
      queryParams: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  Future<RideModel> syncRealtimeState(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.syncRealtimeState,
      queryParams: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    final rideData = data['authoritative_state'] ?? data['ride'] ?? data;
    return RideModel.fromJson(rideData);
  }

  Future<RideModel> cancelRide(String rideId, {required String reason}) async {
    final res = await apiClient.post(
      ApiEndpoints.cancelRide,
      body: {
        'ride_id': rideId,
        'reason': reason,
        'cancelled_by': 'RIDER',
      },
    );
    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  Future<RideModel> confirmPayment(String rideId) async {
    final res = await apiClient.post(
      ApiEndpoints.confirmPayment,
      body: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }
}

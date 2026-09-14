import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/trip_history.dart';
import '../../domain/repositories/i_ride_repository.dart';
import '../models/fare_estimate_model.dart';
import '../models/ride_model.dart';
import '../models/trip_history_model.dart';

class RideRepository implements IRideRepository {
  final IApiClient apiClient;

  RideRepository({required this.apiClient});

  @override
  Future<List<FareEstimateModel>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    double? destLat,
    double? destLng,
    double? destinationLat,
    double? destinationLng,
    String? serviceArea,
  }) async {
    final dLat = destLat ?? destinationLat ?? 0.0;
    final dLng = destLng ?? destinationLng ?? 0.0;

    final res = await apiClient.post(
      ApiEndpoints.getFareEstimatesAll,
      body: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': dLat,
        'destination_lng': dLng,
        'service_area': ?serviceArea,
      },
    );

    final List<dynamic> list = res is List ? res : (res['data'] ?? []);
    return list.map((item) => FareEstimateModel.fromJson(item)).toList();
  }

  @override
  Future<RideModel> requestRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    double? destLat,
    double? destLng,
    String? destAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
    required String vehicleCategory,
    double? distanceKm,
    double? estimatedDurationMins,
    bool autoSearch = true,
  }) async {
    final dLat = destLat ?? destinationLat ?? 0.0;
    final dLng = destLng ?? destinationLng ?? 0.0;
    final dAddr = destAddress ?? destinationAddress ?? '';

    final res = await apiClient.post(
      ApiEndpoints.requestRide,
      body: {
        'pickup_address': pickupAddress,
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_address': dAddr,
        'destination_lat': dLat,
        'destination_lng': dLng,
        'vehicle_category': vehicleCategory,
        'distance_km': ?distanceKm,
        'estimated_duration_mins': ?estimatedDurationMins,
        'auto_search': autoSearch ? 1 : 0,
      },
    );

    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  @override
  Future<RideModel> getRide(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.getRide,
      queryParams: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  @override
  Future<RideModel> syncRealtimeState(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.syncRealtimeState,
      queryParams: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    final rideData = data['authoritative_state'] ?? data['ride'] ?? data;
    return RideModel.fromJson(rideData);
  }

  @override
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

  @override
  Future<List<TripHistoryItem>> getTripHistory() async {
    // Queries completed or past rides for current rider
    final res = await apiClient.get(
      ApiEndpoints.getRide,
      queryParams: {'limit': 50},
    );

    final List<dynamic> list = res is List
        ? res
        : (res['data'] is List ? res['data'] : (res['rides'] is List ? res['rides'] : []));

    return list.map((item) => TripHistoryModel.fromJson(item)).toList();
  }

  // Backward compatibility alias for earlier confirmPayment test/call
  Future<RideModel> confirmPayment(String rideId) async {
    final res = await apiClient.post(
      ApiEndpoints.confirmPayment,
      body: {'ride_id': rideId},
    );
    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }
}

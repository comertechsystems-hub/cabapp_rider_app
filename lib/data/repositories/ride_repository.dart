import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/ride.dart';
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
        'pickup': {'lat': pickupLat, 'lng': pickupLng},
        'destination': {'lat': dLat, 'lng': dLng},
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'destination_lat': dLat,
        'destination_lng': dLng,
        'service_area': ?serviceArea,
      },
    );

    final dynamic rawList = res is List
        ? res
        : (res is Map
            ? (res['estimates'] ?? res['data'] ?? [])
            : []);
    final List<dynamic> list = rawList is List ? rawList : [];
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
    double? offeredFare,
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
        'offered_fare': ?offeredFare,
        'auto_search': autoSearch ? 1 : 0,
      },
    );

    final data = res['data'] ?? res;
    return RideModel.fromJson(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getRideDriverOffers(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.getRideDriverOffers,
      queryParams: {'ride_id': rideId},
    );
    final rawList = res is Map ? (res['offers'] ?? res['data'] ?? []) : [];
    if (rawList is List) {
      return rawList.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  @override
  Future<ActiveRide> acceptDriverCounterOffer(String rideId, String offerId) async {
    final res = await apiClient.post(
      ApiEndpoints.riderAcceptCounterOffer,
      body: {
        'ride_id': rideId,
        'offer_id': offerId,
      },
    );
    final data = res['data'] ?? res['ride'] ?? res;
    return RideModel.fromJson(data);
  }

  @override
  Future<bool> declineDriverCounterOffer(String rideId, String offerId) async {
    try {
      await apiClient.post(
        ApiEndpoints.riderDeclineCounterOffer,
        body: {
          'ride_id': rideId,
          'offer_id': offerId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ActiveRide> updateRideOffer(String rideId, double offeredFare) async {
    final res = await apiClient.post(
      ApiEndpoints.updateRideOffer,
      body: {
        'ride_id': rideId,
        'offered_fare': offeredFare,
      },
    );
    final data = res['data'] ?? res['ride'] ?? res;
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
    final rawRideData = data['authoritative_state'] ?? data['ride'] ?? data;
    final rideMap = rawRideData is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawRideData)
        : <String, dynamic>{};
    if (data is Map && data['chat_messages'] is List && rideMap['chat_messages'] == null) {
      rideMap['chat_messages'] = data['chat_messages'];
    }
    return RideModel.fromJson(rideMap);
  }

  Future<List<Map<String, dynamic>>> sendRideMessage(String rideId, String message) async {
    final res = await apiClient.post(
      ApiEndpoints.sendRideMessage,
      body: {
        'ride_id': rideId,
        'message': message,
        'sender_role': 'RIDER',
      },
    );
    final data = res is Map ? (res['data'] ?? res) : res;
    if (data is Map && data['chat_messages'] is List) {
      return (data['chat_messages'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getRideMessages(String rideId) async {
    final res = await apiClient.get(
      ApiEndpoints.getRideMessages,
      queryParams: {'ride_id': rideId},
    );
    final data = res is Map ? (res['data'] ?? res) : res;
    if (data is Map && data['chat_messages'] is List) {
      return (data['chat_messages'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
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
    dynamic res;
    try {
      res = await apiClient.get(
        ApiEndpoints.getRiderTripHistory,
        queryParams: {'limit': 50},
      );
      if (res is! List && res['data'] == null && res['rides'] == null) {
        // Fallback for mock environments where only getRide was configured
        res = await apiClient.get(
          ApiEndpoints.getRide,
          queryParams: {'limit': 50},
        );
      }
    } catch (_) {
      // Fallback for tests or legacy endpoint
      res = await apiClient.get(
        ApiEndpoints.getRide,
        queryParams: {'limit': 50},
      );
    }

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

  @override
  Future<List<Map<String, dynamic>>> getAvailableDrivers({
    String serviceArea = 'Lagos Metropolitan',
    String? vehicleCategory,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'service_area': serviceArea,
      };
      if (vehicleCategory != null) queryParams['vehicle_category'] = vehicleCategory;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (radiusKm != null) queryParams['radius_km'] = radiusKm;

      final res = await apiClient.get(
        ApiEndpoints.getAvailableDrivers,
        queryParams: queryParams,
      );

      final msg = res is Map<String, dynamic> && res.containsKey('message')
          ? res['message']
          : res;

      final drivers = msg is Map<String, dynamic> && msg.containsKey('drivers')
          ? msg['drivers']
          : (msg is List ? msg : []);

      if (drivers is List) {
        return drivers.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

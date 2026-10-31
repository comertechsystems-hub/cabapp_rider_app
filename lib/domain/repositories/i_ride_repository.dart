import '../entities/fare_estimate.dart';
import '../entities/ride.dart';
import '../entities/trip_history.dart';

abstract class IRideRepository {
  Future<List<FareEstimate>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    String? serviceArea,
  });

  Future<ActiveRide> requestRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double destLat,
    required double destLng,
    required String destinationAddress,
    required String vehicleCategory,
    double? distanceKm,
    double? estimatedDurationMins,
    double? offeredFare,
    bool autoSearch = true,
  });

  Future<ActiveRide> getRide(String rideId);
  Future<ActiveRide?> getMyActiveRide();
  Future<ActiveRide> syncRealtimeState(String rideId);
  Future<ActiveRide> cancelRide(String rideId, {required String reason});
  Future<List<TripHistoryItem>> getTripHistory();
  Future<List<Map<String, dynamic>>> getAvailableDrivers({
    String serviceArea,
    String? vehicleCategory,
    double? latitude,
    double? longitude,
    double? radiusKm,
  });
  Future<List<Map<String, dynamic>>> getRideDriverOffers(String rideId);
  Future<ActiveRide> acceptDriverCounterOffer(String rideId, String offerId);
  Future<bool> declineDriverCounterOffer(String rideId, String offerId);
  Future<ActiveRide> updateRideOffer(String rideId, double offeredFare);
}

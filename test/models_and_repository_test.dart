import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/data/models/fare_estimate_model.dart';
import 'package:rider_app/data/models/ride_model.dart';
import 'package:rider_app/data/models/user_profile_model.dart';

void main() {
  group('Rider App Domain Models', () {
    test('FareEstimateModel serializes and deserializes correctly', () {
      final json = {
        'vehicle_category': 'COMFORT',
        'category_name': 'Comfort Sedan',
        'base_fare': 1200.0,
        'distance_fare': 880.0,
        'time_fare': 180.0,
        'subtotal': 2260.0,
        'total_fare': 2260.0,
        'currency': 'NGN',
        'distance_km': 4.0,
        'estimated_duration_mins': 6.0,
      };

      final model = FareEstimateModel.fromJson(json);
      expect(model.vehicleCategory, 'COMFORT');
      expect(model.categoryName, 'Comfort Sedan');
      expect(model.totalFare, 2260.0);
      expect(model.distanceKm, 4.0);

      final outJson = model.toJson();
      expect(outJson['vehicle_category'], 'COMFORT');
      expect(outJson['total_fare'], 2260.0);
    });

    test('RideModel state flags evaluate correctly across lifecycle', () {
      final rideSearching = RideModel.fromJson({
        'name': 'RD-2026-00001',
        'rider': 'RDR-001',
        'status': 'SEARCHING',
        'pickup_address': 'Marina, Lagos',
        'pickup_lat': 6.4531,
        'pickup_lng': 3.4328,
        'destination_address': 'Ikoyi, Lagos',
        'destination_lat': 6.4500,
        'destination_lng': 3.4500,
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
        'start_otp': '7412',
      });

      expect(rideSearching.isSearching, isTrue);
      expect(rideSearching.isAssigned, isFalse);
      expect(rideSearching.startOtp, '7412');

      final rideInProgress = RideModel.fromJson({
        'name': 'RD-2026-00001',
        'rider': 'RDR-001',
        'status': 'TRIP_STARTED',
        'pickup_address': 'Marina, Lagos',
        'pickup_lat': 6.4531,
        'pickup_lng': 3.4328,
        'destination_address': 'Ikoyi, Lagos',
        'destination_lat': 6.4500,
        'destination_lng': 3.4500,
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
      });

      expect(rideInProgress.isInProgress, isTrue);
      expect(rideInProgress.isCompleted, isFalse);

      final rideCompleted = RideModel.fromJson({
        'name': 'RD-2026-00001',
        'rider': 'RDR-001',
        'status': 'PAYMENT_CONFIRMED',
        'pickup_address': 'Marina, Lagos',
        'pickup_lat': 6.4531,
        'pickup_lng': 3.4328,
        'destination_address': 'Ikoyi, Lagos',
        'destination_lat': 6.4500,
        'destination_lng': 3.4500,
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
      });

      expect(rideCompleted.isCompleted, isTrue);
    });

    test('UserProfileModel parses full name and credentials', () {
      final json = {
        'email': 'rider@cabapp.com.ng',
        'phone': '+2348012345678',
        'full_name': 'Amina Bello',
        'rider_id': 'RDR-2026-0010',
        'status': 'ACTIVE',
        'rating': 4.95,
        'total_rides': 18,
      };

      final profile = UserProfileModel.fromJson(json);
      expect(profile.email, 'rider@cabapp.com.ng');
      expect(profile.phone, '+2348012345678');
      expect(profile.fullName, 'Amina Bello');
      expect(profile.rating, 4.95);
      expect(profile.totalRides, 18);
    });
  });
}

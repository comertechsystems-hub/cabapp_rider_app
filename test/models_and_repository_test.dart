import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/data/models/driver_details_model.dart';
import 'package:rider_app/data/models/driver_location_model.dart';
import 'package:rider_app/data/models/fare_estimate_model.dart';
import 'package:rider_app/data/models/payment_model.dart';
import 'package:rider_app/data/models/rating_model.dart';
import 'package:rider_app/data/models/ride_model.dart';
import 'package:rider_app/data/models/rider_profile_model.dart';
import 'package:rider_app/data/models/support_model.dart';
import 'package:rider_app/data/models/trip_history_model.dart';
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

    test('UserProfileModel and RiderProfileModel parse details correctly', () {
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

      final riderModel = RiderProfileModel.fromJson({
        'name': 'RDR-001',
        'user': 'amina@cabapp.ng',
        'phone_number': '+2348012345678',
        'first_name': 'Amina',
        'last_name': 'Bello',
        'rating': 4.9,
        'total_trips': 25,
        'status': 'ACTIVE',
        'emergency_contact_name': 'Hassan Bello',
        'emergency_contact_phone': '+2348099998888',
      });
      expect(riderModel.fullName, 'Amina Bello');
      expect(riderModel.hasEmergencyContact, isTrue);
      expect(riderModel.isActive, isTrue);
    });

    test('DriverDetailsModel and DriverLocationModel deserialize accurately', () {
      final driverJson = {
        'driver': 'DRV-001',
        'driver_name': 'Emeka Okafor',
        'driver_phone': '+2348022223333',
        'vehicle_make': 'Toyota',
        'vehicle_model': 'Corolla',
        'vehicle_color': 'Navy Blue',
        'license_plate': 'LAG-889-AA',
        'vehicle_category': 'ECONOMY',
        'rating': 4.88,
        'total_trips': 142,
      };

      final driver = DriverDetailsModel.fromJson(driverJson);
      expect(driver.name, 'Emeka Okafor');
      expect(driver.vehicleDescription, 'Navy Blue Toyota Corolla');
      expect(driver.rating, 4.88);

      final locJson = {
        'ride_id': 'RD-100',
        'driver_id': 'DRV-001',
        'latitude': 6.4521,
        'longitude': 3.4210,
        'bearing_degrees': 180.0,
        'speed_kmh': 45.2,
      };
      final loc = DriverLocationModel.fromJson(locJson);
      expect(loc.latitude, 6.4521);
      expect(loc.bearing, 180.0);
      expect(loc.speedKmh, 45.2);
    });

    test('PaymentModel, RatingModel, and SupportTicketModel parse accurately', () {
      final payment = PaymentModel.fromJson({
        'ride_id': 'RD-100',
        'payment_method': 'BANK_TRANSFER',
        'amount': 3500.0,
        'status': 'RIDER_CONFIRMED',
        'transaction_reference': 'TXN-998877',
      });
      expect(payment.isRiderConfirmed, isTrue);
      expect(payment.isSettled, isTrue);
      expect(payment.amount, 3500.0);

      final rating = RatingModel.fromJson({
        'ride_id': 'RD-100',
        'rating': 5,
        'review': 'Great and respectful driver!',
        'tags': ['Polite driver', 'Safe driving'],
      });
      expect(rating.rating, 5);
      expect(rating.tags.length, 2);

      final ticket = SupportTicketModel.fromJson({
        'name': 'TCK-2026-001',
        'subject': 'Forgot item in car',
        'category': 'RIDE_ISSUE',
        'description': 'Left my umbrella on the backseat',
        'status': 'OPEN',
      });
      expect(ticket.isOpen, isTrue);
      expect(ticket.category, 'RIDE_ISSUE');

      final contact = EmergencyContactModel.fromJson({
        'name': 'EMG-01',
        'contact_name': 'Dr. Alabi',
        'phone': '+2348033334444',
        'relationship': 'Uncle',
        'is_primary': 1,
      });
      expect(contact.isPrimary, isTrue);
      expect(contact.relationship, 'Uncle');

      final history = TripHistoryModel.fromJson({
        'name': 'RD-099',
        'status': 'TRIP_COMPLETED',
        'pickup_address': 'Marina',
        'destination_address': 'Lekki',
        'final_fare': 2800.0,
        'vehicle_category': 'ECONOMY',
      });
      expect(history.isCompleted, isTrue);
      expect(history.fare, 2800.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/services/realtime_service.dart';
import 'package:rider_app/domain/entities/driver_details.dart';
import 'package:rider_app/domain/entities/driver_location.dart';
import 'package:rider_app/domain/entities/fare_estimate.dart';
import 'package:rider_app/domain/entities/payment.dart';
import 'package:rider_app/domain/entities/rating.dart';
import 'package:rider_app/domain/entities/ride.dart';
import 'package:rider_app/domain/entities/rider_profile.dart';
import 'package:rider_app/domain/entities/support.dart';
import 'package:rider_app/domain/entities/trip_history.dart';
import 'package:rider_app/domain/repositories/i_auth_repository.dart';
import 'package:rider_app/domain/repositories/i_payment_repository.dart';
import 'package:rider_app/domain/repositories/i_ratings_repository.dart';
import 'package:rider_app/domain/repositories/i_ride_repository.dart';
import 'package:rider_app/domain/repositories/i_rider_repository.dart';
import 'package:rider_app/domain/repositories/i_support_repository.dart';
import 'package:rider_app/presentation/viewmodels/active_ride_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/emergency_contact_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/payment_status_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/rating_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/ride_booking_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/rider_profile_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/support_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/trip_history_viewmodel.dart';

// Mocks for ViewModels test
class MockAuthRepo implements IAuthRepository {
  bool otpRequested = false;
  bool loggedIn = false;

  @override
  Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    otpRequested = true;
    return {'success': true};
  }

  @override
  Future<RiderProfile> verifyOtp({required String phoneNumber, required String otp}) async {
    loggedIn = true;
    return RiderProfile(
      id: 'RDR-001',
      user: 'rider@cabapp.ng',
      phoneNumber: phoneNumber,
      firstName: 'Fatima',
      lastName: 'Danjuma',
    );
  }

  @override
  Future<RiderProfile?> getCurrentUser() async {
    return loggedIn
        ? const RiderProfile(id: 'RDR-001', user: 'u', phoneNumber: 'p')
        : null;
  }

  @override
  Future<void> logout() async {
    loggedIn = false;
  }
}

class MockRiderRepo implements IRiderRepository {
  RiderProfile profile = const RiderProfile(
    id: 'RDR-001',
    user: 'rider@cabapp.ng',
    phoneNumber: '+2348011112222',
    firstName: 'Fatima',
    lastName: 'Danjuma',
  );

  @override
  Future<RiderProfile> getProfile() async => profile;

  @override
  Future<RiderProfile> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    profile = RiderProfile(
      id: profile.id,
      user: profile.user,
      phoneNumber: profile.phoneNumber,
      firstName: firstName ?? profile.firstName,
      lastName: lastName ?? profile.lastName,
      email: email ?? profile.email,
      emergencyContactName: emergencyContactName ?? profile.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? profile.emergencyContactPhone,
    );
    return profile;
  }
}

class MockRideRepo implements IRideRepository {
  @override
  Future<List<FareEstimate>> getFareEstimates({
    required double pickupLat,
    required double pickupLng,
    required double destLat,
    required double destLng,
    String? serviceArea,
  }) async {
    return const [
      FareEstimate(
        vehicleCategory: 'ECONOMY',
        categoryName: 'Economy Go',
        baseFare: 1000.0,
        distanceRate: 200.0,
        timeRate: 30.0,
        minimumFare: 1000.0,
        estimatedDurationMins: 10.0,
        distanceKm: 5.0,
        totalFare: 2300.0,
      ),
      FareEstimate(
        vehicleCategory: 'COMFORT',
        categoryName: 'Comfort Sedan',
        baseFare: 1500.0,
        distanceRate: 300.0,
        timeRate: 40.0,
        minimumFare: 1500.0,
        estimatedDurationMins: 10.0,
        distanceKm: 5.0,
        totalFare: 3400.0,
      ),
    ];
  }

  @override
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
    bool autoSearch = true,
  }) async {
    return ActiveRide(
      id: 'RD-001',
      status: 'SEARCHING',
      riderId: 'RDR-001',
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationAddress: destinationAddress,
      destinationLat: destLat,
      destinationLng: destLng,
      vehicleCategory: vehicleCategory,
      totalFare: 2300.0,
      startOtp: '8822',
    );
  }

  @override
  Future<ActiveRide> getRide(String rideId) async => ActiveRide(
        id: rideId,
        status: 'SEARCHING',
        riderId: 'RDR-001',
        pickupAddress: 'A',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'B',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2000,
      );

  @override
  Future<ActiveRide> syncRealtimeState(String rideId) async => ActiveRide(
        id: rideId,
        status: 'DRIVER_ARRIVED',
        riderId: 'RDR-001',
        pickupAddress: 'A',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'B',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2000,
        startOtp: '8822',
        driverDetails: const DriverDetails(
          id: 'DRV-1',
          name: 'Ibrahim Musa',
          phoneNumber: '+2348000000000',
          vehicleMake: 'Toyota',
          vehicleModel: 'Yaris',
          vehicleColor: 'Black',
          licensePlate: 'ABC-123-XY',
          vehicleCategory: 'ECONOMY',
        ),
      );

  @override
  Future<ActiveRide> cancelRide(String rideId, {required String reason}) async => ActiveRide(
        id: rideId,
        status: 'CANCELLED',
        riderId: 'RDR-001',
        pickupAddress: 'A',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'B',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2000,
      );

  @override
  Future<List<TripHistoryItem>> getTripHistory() async {
    return [
      TripHistoryItem(
        rideId: 'RD-001',
        status: 'TRIP_COMPLETED',
        pickupAddress: 'Victoria Island',
        destinationAddress: 'Lekki',
        fare: 2300.0,
        vehicleCategory: 'ECONOMY',
        createdAt: DateTime.now(),
      ),
      TripHistoryItem(
        rideId: 'RD-002',
        status: 'CANCELLED',
        pickupAddress: 'Ikeja',
        destinationAddress: 'Maryland',
        fare: 1500.0,
        vehicleCategory: 'ECONOMY',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

class MockPaymentRepo implements IPaymentRepository {
  @override
  Future<PaymentRecord> getPayment(String rideId) async => PaymentRecord(
        rideId: rideId,
        amount: 2300.0,
        status: 'PENDING',
      );

  @override
  Future<PaymentRecord> confirmPayment({
    required String rideId,
    required String paymentMethod,
    String? transactionReference,
  }) async =>
      PaymentRecord(
        rideId: rideId,
        amount: 2300.0,
        paymentMethod: paymentMethod,
        transactionReference: transactionReference,
        status: 'RIDER_CONFIRMED',
      );

  @override
  Future<PaymentRecord> disputePayment({required String rideId, required String reason}) async =>
      PaymentRecord(
        rideId: rideId,
        amount: 2300.0,
        status: 'DISPUTED',
        disputeReason: reason,
      );
}

class MockRatingsRepo implements IRatingsRepository {
  @override
  Future<RideRating> submitRating({
    required String rideId,
    required int rating,
    String? review,
    List<String>? tags,
  }) async =>
      RideRating(
        rideId: rideId,
        rating: rating,
        review: review,
        tags: tags ?? [],
      );

  @override
  Future<List<RideRating>> getUserRatings() async => [];
}

class MockSupportRepo implements ISupportRepository {
  final List<SupportTicket> tickets = [];
  final List<EmergencyContact> contacts = [];

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String description,
    String? rideId,
    String? priority,
  }) async {
    final t = SupportTicket(
      id: 'TCK-${tickets.length + 1}',
      subject: subject,
      category: category,
      description: description,
      rideId: rideId,
      createdAt: DateTime.now(),
    );
    tickets.add(t);
    return t;
  }

  @override
  Future<List<SupportTicket>> getTickets() async => tickets;

  @override
  Future<EmergencyContact> addEmergencyContact({
    required String contactName,
    required String phone,
    required String relationship,
    String? email,
    bool isPrimary = false,
  }) async {
    final c = EmergencyContact(
      id: 'EMG-${contacts.length + 1}',
      contactName: contactName,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
    contacts.add(c);
    return c;
  }

  @override
  Future<List<EmergencyContact>> getEmergencyContacts() async => contacts;

  @override
  Future<bool> deleteEmergencyContact(String contactId) async {
    contacts.removeWhere((c) => c.id == contactId);
    return true;
  }

  @override
  Future<Map<String, dynamic>> triggerEmergencySos({
    required String rideId,
    double? lat,
    double? lng,
    String? address,
  }) async =>
      {'success': true, 'incident_id': 'INC-SOS-123'};
}

void main() {
  group('AuthViewModel State Transitions', () {
    test('requestOtp transitions from loading to success', () async {
      final repo = MockAuthRepo();
      final vm = AuthViewModel(repo);

      expect(vm.isOtpSent, isFalse);
      final ok = await vm.requestOtp('+2348011223344');
      expect(ok, isTrue);
      expect(vm.isOtpSent, isTrue);
      expect(vm.isSuccess, isTrue);
    });

    test('verifyOtp transitions to authenticated and sets profile', () async {
      final repo = MockAuthRepo();
      final vm = AuthViewModel(repo);

      await vm.requestOtp('+2348011223344');
      final ok = await vm.verifyOtp('123456');
      expect(ok, isTrue);
      expect(vm.isAuthenticated, isTrue);
      expect(vm.profile?.fullName, 'Fatima Danjuma');
    });

    test('logout resets auth state and profile', () async {
      final repo = MockAuthRepo();
      final vm = AuthViewModel(repo);

      await vm.requestOtp('+2348011223344');
      await vm.verifyOtp('123456');
      expect(vm.isAuthenticated, isTrue);

      await vm.logout();
      expect(vm.isAuthenticated, isFalse);
      expect(vm.profile, isNull);
    });
  });

  group('RiderProfileViewModel', () {
    test('loadProfile and updateProfile update state', () async {
      final repo = MockRiderRepo();
      final vm = RiderProfileViewModel(riderRepo: repo);

      await vm.loadProfile();
      expect(vm.isSuccess, isTrue);
      expect(vm.profile?.fullName, 'Fatima Danjuma');

      final updated = await vm.updateProfile(
        firstName: 'Hauwa',
        emergencyContactPhone: '+2348099990000',
      );
      expect(updated, isTrue);
      expect(vm.profile?.firstName, 'Hauwa');
      expect(vm.profile?.hasEmergencyContact, isTrue);
    });
  });

  group('RideBookingViewModel & Estimation', () {
    test('setPickup, setDestination, fetchFareEstimates, and bookRide', () async {
      final repo = MockRideRepo();
      final vm = RideBookingViewModel(rideRepo: repo);

      expect(vm.hasValidRoute, isFalse);
      vm.setPickup('Victoria Island', 6.42, 3.42);
      vm.setDestination('Lekki Phase 1', 6.44, 3.47);
      expect(vm.hasValidRoute, isTrue);

      final ok = await vm.fetchFareEstimates();
      expect(ok, isTrue);
      expect(vm.fareEstimates.length, 2);
      expect(vm.selectedCategory?.vehicleCategory, 'ECONOMY');

      final ride = await vm.bookRide();
      expect(ride, isNotNull);
      expect(ride?.isSearching, isTrue);
      expect(ride?.startOtp, '8822');
      expect(vm.bookedRide?.id, 'RD-001');
    });
  });

  group('ActiveRideViewModel & Realtime Streams', () {
    test('setActiveRide starts search timer and cancels ride', () async {
      final repo = MockRideRepo();
      final realtime = MockRealtimeService();
      final vm = ActiveRideViewModel(rideRepo: repo, realtimeService: realtime);

      const ride = ActiveRide(
        id: 'RD-001',
        status: 'SEARCHING',
        riderId: 'RDR-001',
        pickupAddress: 'VI',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'Lekki',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2300,
        startOtp: '8822',
      );

      vm.setActiveRide(ride);
      expect(vm.isSearching, isTrue);
      expect(vm.startOtp, '8822');

      final cancelled = await vm.cancelRide('Change of plans');
      expect(cancelled, isTrue);
      expect(vm.isCancelled, isTrue);
    });

    test('realtimeService streams push status and location updates', () async {
      final repo = MockRideRepo();
      final realtime = MockRealtimeService();
      final vm = ActiveRideViewModel(rideRepo: repo, realtimeService: realtime);

      const ride = ActiveRide(
        id: 'RD-001',
        status: 'SEARCHING',
        riderId: 'RDR-001',
        pickupAddress: 'VI',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'Lekki',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2300,
      );
      vm.setActiveRide(ride);

      // Push real-time driver arrival
      const updatedRide = ActiveRide(
        id: 'RD-001',
        status: 'DRIVER_ARRIVED',
        riderId: 'RDR-001',
        pickupAddress: 'VI',
        pickupLat: 1,
        pickupLng: 1,
        destinationAddress: 'Lekki',
        destinationLat: 2,
        destinationLng: 2,
        vehicleCategory: 'ECONOMY',
        totalFare: 2300,
        startOtp: '8822',
        driverDetails: DriverDetails(
          id: 'DRV-1',
          name: 'Ibrahim Musa',
          phoneNumber: '+2348000000000',
          vehicleMake: 'Toyota',
          vehicleModel: 'Yaris',
          vehicleColor: 'Black',
          licensePlate: 'ABC-123-XY',
          vehicleCategory: 'ECONOMY',
        ),
      );
      realtime.pushRideUpdate(updatedRide);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(vm.isDriverArriving, isTrue);
      expect(vm.driverDetails?.name, 'Ibrahim Musa');

      // Push driver location event
      final locEvent = DriverLocationEvent(
        rideId: 'RD-001',
        driverId: 'DRV-1',
        latitude: 6.4250,
        longitude: 3.4210,
        bearing: 90.0,
        speedKmh: 35.0,
        recordedAt: DateTime.now(),
      );
      realtime.pushDriverLocation(locEvent);

      await Future.delayed(const Duration(milliseconds: 10));
      expect(vm.driverLocation?.latitude, 6.4250);
      expect(vm.driverLocation?.speedKmh, 35.0);
    });
  });

  group('PaymentStatusViewModel, RatingViewModel, TripHistoryViewModel', () {
    test('PaymentStatusViewModel handles direct P2P confirmation and dispute', () async {
      final repo = MockPaymentRepo();
      final vm = PaymentStatusViewModel(paymentRepo: repo);

      await vm.fetchPayment('RD-001');
      expect(vm.paymentRecord?.isPending, isTrue);

      vm.setPaymentMethod('BANK_TRANSFER');
      vm.setTransactionReference('TXN-887766');
      final confirmed = await vm.confirmPaymentPaid('RD-001');
      expect(confirmed, isTrue);
      expect(vm.paymentRecord?.isRiderConfirmed, isTrue);
      expect(vm.paymentRecord?.transactionReference, 'TXN-887766');

      final disputed = await vm.raiseDispute('RD-001', 'Overcharged');
      expect(disputed, isTrue);
      expect(vm.paymentRecord?.isDisputed, isTrue);
    });

    test('RatingViewModel sets score, toggles tags, and submits rating', () async {
      final repo = MockRatingsRepo();
      final vm = RatingViewModel(ratingsRepo: repo);

      vm.setScore(4);
      vm.toggleTag('Polite driver');
      vm.toggleTag('Clean vehicle');
      vm.setReview('Very courteous driver!');

      expect(vm.score, 4);
      expect(vm.selectedTags.length, 2);

      final ok = await vm.submitRating('RD-001');
      expect(ok, isTrue);
      expect(vm.submittedRating?.rating, 4);
      expect(vm.submittedRating?.review, 'Very courteous driver!');
    });

    test('TripHistoryViewModel loads and filters completed vs cancelled', () async {
      final repo = MockRideRepo();
      final vm = TripHistoryViewModel(rideRepo: repo);

      await vm.loadTripHistory();
      expect(vm.filteredTrips.length, 2);

      vm.setFilter(HistoryFilter.completed);
      expect(vm.filteredTrips.length, 1);
      expect(vm.filteredTrips.first.isCompleted, isTrue);

      vm.setFilter(HistoryFilter.cancelled);
      expect(vm.filteredTrips.length, 1);
      expect(vm.filteredTrips.first.isCancelled, isTrue);
    });
  });

  group('SupportViewModel and EmergencyContactViewModel', () {
    test('SupportViewModel creates tickets and triggers SOS', () async {
      final repo = MockSupportRepo();
      final vm = SupportViewModel(supportRepo: repo);

      final ticket = await vm.createTicket(
        subject: 'Car air conditioning issue',
        category: 'RIDE_ISSUE',
        description: 'AC was not functioning',
      );
      expect(ticket, isNotNull);
      expect(vm.tickets.length, 1);

      final sos = await vm.triggerEmergencySos(rideId: 'RD-001');
      expect(sos, isTrue);
      expect(vm.sosTriggered, isTrue);
    });

    test('EmergencyContactViewModel adds and deletes contacts', () async {
      final repo = MockSupportRepo();
      final vm = EmergencyContactViewModel(supportRepo: repo);

      final ok = await vm.addContact(
        contactName: 'Adeola Johnson',
        phone: '+2348055556666',
        relationship: 'Mother',
        isPrimary: true,
      );
      expect(ok, isTrue);
      expect(vm.contacts.length, 1);
      expect(vm.contacts.first.isPrimary, isTrue);

      final deleted = await vm.deleteContact('EMG-1');
      expect(deleted, isTrue);
      expect(vm.contacts.isEmpty, isTrue);
    });
  });
}

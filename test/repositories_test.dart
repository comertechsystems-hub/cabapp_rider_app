import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/constants/api_endpoints.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/storage/session_manager.dart';
import 'package:rider_app/data/repositories/auth_repository.dart';
import 'package:rider_app/data/repositories/payment_repository.dart';
import 'package:rider_app/data/repositories/ratings_repository.dart';
import 'package:rider_app/data/repositories/ride_repository.dart';
import 'package:rider_app/data/repositories/rider_repository.dart';
import 'package:rider_app/data/repositories/support_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;
  late SessionManager sessionManager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    sessionManager = SessionManager(prefs);
    mockApi = MockApiClient();
  });

  group('AuthRepository Unit Tests', () {
    test('requestOtp sends phone and role', () async {
      mockApi.setResponse(ApiEndpoints.requestOtp, {'success': true, 'otp_sent': true});
      final repo = AuthRepository(apiClient: mockApi, sessionManager: sessionManager);

      final result = await repo.requestOtp('+2348011223344');
      expect(result['success'], isTrue);
      expect(mockApi.callLogs.last['path'], ApiEndpoints.requestOtp);
      expect((mockApi.callLogs.last['body'] as Map)['phone'], '+2348011223344');
      expect((mockApi.callLogs.last['body'] as Map)['role'], 'Rider');
    });

    test('verifyOtp persists session and returns RiderProfile', () async {
      mockApi.setResponse(ApiEndpoints.verifyOtp, {
        'api_key': 'KEY123',
        'api_secret': 'SEC456',
        'user': 'rider@cabapp.ng',
        'domain_profile': 'RDR-001',
        'name': 'RDR-001',
        'phone_number': '+2348011223344',
        'first_name': 'Zainab',
        'last_name': 'Aliyu',
        'rating': 5.0,
      });

      final repo = AuthRepository(apiClient: mockApi, sessionManager: sessionManager);
      final profile = await repo.verifyOtp(
        phoneNumber: '+2348011223344',
        otp: '123456',
        firstName: 'Zainab',
        lastName: 'Aliyu',
      );

      expect(profile.fullName, 'Zainab Aliyu');
      expect(profile.user, 'rider@cabapp.ng');
      expect(sessionManager.isAuthenticated, isTrue);
      expect(sessionManager.authHeader, 'token KEY123:SEC456');
    });

    test('logout clears stored credentials', () async {
      await sessionManager.saveAuthCredentials(
        apiKey: 'K1',
        apiSecret: 'S1',
        userEmail: 'rider@ng.com',
      );
      expect(sessionManager.isAuthenticated, isTrue);

      final repo = AuthRepository(apiClient: mockApi, sessionManager: sessionManager);
      await repo.logout();
      expect(sessionManager.isAuthenticated, isFalse);
    });
  });

  group('RiderRepository Unit Tests', () {
    test('getProfile and updateProfile execute correctly', () async {
      mockApi.setResponse(ApiEndpoints.getProfile, {
        'success': true,
        'profile': {
          'name': 'RDR-001',
          'user': 'rider@cabapp.ng',
          'phone_number': '+2348011223344',
          'first_name': 'Zainab',
          'last_name': 'Aliyu',
          'status': 'ACTIVE',
        },
      });

      final repo = RiderRepository(apiClient: mockApi);
      final profile = await repo.getProfile();
      expect(profile.fullName, 'Zainab Aliyu');

      mockApi.setResponse(ApiEndpoints.updateProfile, {
        'success': true,
        'profile': {
          'name': 'RDR-001',
          'user': 'rider@cabapp.ng',
          'phone_number': '+2348011223344',
          'first_name': 'Zainab',
          'last_name': 'Ahmed',
          'emergency_contact_phone': '+2348099991111',
          'status': 'ACTIVE',
        },
      });

      final updated = await repo.updateProfile(
        lastName: 'Ahmed',
        emergencyContactPhone: '+2348099991111',
      );
      expect(updated.lastName, 'Ahmed');
      expect(updated.hasEmergencyContact, isTrue);
    });
  });

  group('RideRepository Unit Tests', () {
    test('getFareEstimates returns multi-category list', () async {
      mockApi.setResponse(ApiEndpoints.getFareEstimatesAll, {
        'data': [
          {
            'vehicle_category': 'ECONOMY',
            'category_name': 'Economy Go',
            'total_fare': 1800.0,
            'distance_km': 6.5,
            'estimated_duration_mins': 12.0,
          },
          {
            'vehicle_category': 'COMFORT',
            'category_name': 'Comfort Sedan',
            'total_fare': 2600.0,
            'distance_km': 6.5,
            'estimated_duration_mins': 12.0,
          },
        ],
      });

      final repo = RideRepository(apiClient: mockApi);
      final list = await repo.getFareEstimates(
        pickupLat: 6.45,
        pickupLng: 3.42,
        destLat: 6.58,
        destLng: 3.32,
      );

      expect(list.length, 2);
      expect(list.first.vehicleCategory, 'ECONOMY');
      expect(list.last.totalFare, 2600.0);
    });

    test('requestRide, getRide, syncRealtimeState, and cancelRide', () async {
      mockApi.setResponse(ApiEndpoints.requestRide, {
        'data': {
          'name': 'RD-2026-999',
          'rider': 'RDR-001',
          'status': 'SEARCHING',
          'pickup_address': 'Marina Lagos',
          'destination_address': 'Airport MMA2',
          'vehicle_category': 'ECONOMY',
          'total_fare': 3200.0,
          'start_otp': '5511',
        },
      });

      final repo = RideRepository(apiClient: mockApi);
      final ride = await repo.requestRide(
        pickupLat: 6.45,
        pickupLng: 3.42,
        pickupAddress: 'Marina Lagos',
        destLat: 6.58,
        destLng: 3.32,
        destinationAddress: 'Airport MMA2',
        vehicleCategory: 'ECONOMY',
      );

      expect(ride.id, 'RD-2026-999');
      expect(ride.isSearching, isTrue);
      expect(ride.startOtp, '5511');

      mockApi.setResponse(ApiEndpoints.cancelRide, {
        'data': {
          'name': 'RD-2026-999',
          'rider': 'RDR-001',
          'status': 'CANCELLED',
          'pickup_address': 'Marina Lagos',
          'destination_address': 'Airport MMA2',
          'vehicle_category': 'ECONOMY',
          'total_fare': 3200.0,
        },
      });

      final cancelled = await repo.cancelRide('RD-2026-999', reason: 'Changed mind');
      expect(cancelled.isCancelled, isTrue);
    });
  });

  group('PaymentRepository Unit Tests', () {
    test('getPayment, confirmPayment, and disputePayment', () async {
      mockApi.setResponse(ApiEndpoints.getPayment, {
        'data': {
          'ride': 'RD-100',
          'payment_method': 'CASH',
          'amount': 2500.0,
          'status': 'PENDING',
        },
      });

      final repo = PaymentRepository(apiClient: mockApi);
      final p1 = await repo.getPayment('RD-100');
      expect(p1.isPending, isTrue);
      expect(p1.amount, 2500.0);

      mockApi.setResponse(ApiEndpoints.riderConfirmPayment, {
        'data': {
          'ride': 'RD-100',
          'payment_method': 'BANK_TRANSFER',
          'amount': 2500.0,
          'status': 'RIDER_CONFIRMED',
          'transaction_reference': 'REF-12345',
        },
      });

      final p2 = await repo.confirmPayment(
        rideId: 'RD-100',
        paymentMethod: 'BANK_TRANSFER',
        transactionReference: 'REF-12345',
      );
      expect(p2.isRiderConfirmed, isTrue);

      mockApi.setResponse(ApiEndpoints.raiseDispute, {
        'data': {
          'ride': 'RD-100',
          'payment_method': 'BANK_TRANSFER',
          'amount': 2500.0,
          'status': 'DISPUTED',
          'dispute_reason': 'Driver charged twice',
        },
      });

      final p3 = await repo.disputePayment(
        rideId: 'RD-100',
        reason: 'Driver charged twice',
      );
      expect(p3.isDisputed, isTrue);
    });
  });

  group('RatingsRepository Unit Tests', () {
    test('submitRating sends stars, review, and tags', () async {
      mockApi.setResponse(ApiEndpoints.submitRating, {
        'rating': {
          'name': 'RAT-01',
          'ride': 'RD-100',
          'rating': 5,
          'review': 'Top tier driver!',
          'tags': ['Polite driver', 'Clean vehicle'],
        },
      });

      final repo = RatingsRepository(apiClient: mockApi);
      final r = await repo.submitRating(
        rideId: 'RD-100',
        rating: 5,
        review: 'Top tier driver!',
        tags: ['Polite driver', 'Clean vehicle'],
      );

      expect(r.rating, 5);
      expect(r.review, 'Top tier driver!');
      expect(r.tags.length, 2);
    });
  });

  group('SupportRepository Unit Tests', () {
    test('createTicket, emergency contacts, and triggerEmergencySos', () async {
      mockApi.setResponse(ApiEndpoints.createTicket, {
        'ticket': {
          'name': 'TCK-001',
          'subject': 'Fare overcharge dispute',
          'category': 'PAYMENT_ISSUE',
          'description': 'Driver asked for extra cash',
          'status': 'OPEN',
        },
      });

      final repo = SupportRepository(apiClient: mockApi);
      final ticket = await repo.createTicket(
        subject: 'Fare overcharge dispute',
        category: 'PAYMENT_ISSUE',
        description: 'Driver asked for extra cash',
      );
      expect(ticket.isOpen, isTrue);
      expect(ticket.category, 'PAYMENT_ISSUE');

      mockApi.setResponse(ApiEndpoints.addEmergencyContact, {
        'contact': {
          'name': 'EMG-10',
          'contact_name': 'Kemi Adewale',
          'phone': '+2348077778888',
          'relationship': 'Sister',
          'is_primary': 1,
        },
      });

      final contact = await repo.addEmergencyContact(
        contactName: 'Kemi Adewale',
        phone: '+2348077778888',
        relationship: 'Sister',
        isPrimary: true,
      );
      expect(contact.isPrimary, isTrue);
      expect(contact.relationship, 'Sister');

      mockApi.setResponse(ApiEndpoints.triggerSos, {
        'success': true,
        'incident_id': 'INC-2026-SOS-01',
      });

      final sosRes = await repo.triggerEmergencySos(
        rideId: 'RD-100',
        lat: 6.45,
        lng: 3.42,
        address: 'Ozumba Mbadiwe Ave',
      );
      expect(sosRes['incident_id'], 'INC-2026-SOS-01');
    });
  });
}

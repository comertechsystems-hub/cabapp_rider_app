import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rider_app/core/constants/api_endpoints.dart';
import 'package:rider_app/core/network/api_client.dart';
import 'package:rider_app/core/services/realtime_service.dart';
import 'package:rider_app/core/storage/session_manager.dart';
import 'package:rider_app/core/theme/app_theme.dart';
import 'package:rider_app/data/models/driver_details_model.dart';
import 'package:rider_app/data/models/ride_model.dart';
import 'package:rider_app/data/repositories/auth_repository.dart';
import 'package:rider_app/data/repositories/payment_repository.dart';
import 'package:rider_app/data/repositories/ratings_repository.dart';
import 'package:rider_app/data/repositories/ride_repository.dart';
import 'package:rider_app/data/repositories/rider_repository.dart';
import 'package:rider_app/data/repositories/support_repository.dart';
import 'package:rider_app/presentation/screens/active_ride_screen.dart';
import 'package:rider_app/presentation/screens/auth_screen.dart';
import 'package:rider_app/presentation/screens/emergency_contacts_screen.dart';
import 'package:rider_app/presentation/screens/home_map_screen.dart';
import 'package:rider_app/presentation/screens/payment_status_dialog.dart';
import 'package:rider_app/presentation/screens/rating_dialog.dart';
import 'package:rider_app/presentation/screens/rider_profile_screen.dart';
import 'package:rider_app/presentation/screens/support_screen.dart';
import 'package:rider_app/presentation/screens/trip_history_screen.dart';
import 'package:rider_app/presentation/viewmodels/active_ride_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/emergency_contact_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/payment_status_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/rating_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/ride_booking_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/ride_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/rider_profile_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/support_viewmodel.dart';
import 'package:rider_app/presentation/viewmodels/trip_history_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;
  late SessionManager sessionManager;
  late MockRealtimeService mockRealtime;

  late AuthRepository authRepo;
  late RiderRepository riderRepo;
  late RideRepository rideRepo;
  late PaymentRepository paymentRepo;
  late RatingsRepository ratingsRepo;
  late SupportRepository supportRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sessionManager = await SessionManager.init();
    mockApi = MockApiClient();
    mockRealtime = MockRealtimeService();

    authRepo = AuthRepository(apiClient: mockApi, sessionManager: sessionManager);
    riderRepo = RiderRepository(apiClient: mockApi);
    rideRepo = RideRepository(apiClient: mockApi);
    paymentRepo = PaymentRepository(apiClient: mockApi);
    ratingsRepo = RatingsRepository(apiClient: mockApi);
    supportRepo = SupportRepository(apiClient: mockApi);
  });

  Widget buildTestApp(
    Widget home, {
    AuthViewModel? authVm,
    RiderProfileViewModel? profileVm,
    RideBookingViewModel? bookingVm,
    ActiveRideViewModel? activeRideVm,
    RideViewModel? rideVm,
    PaymentStatusViewModel? paymentVm,
    TripHistoryViewModel? historyVm,
    RatingViewModel? ratingVm,
    SupportViewModel? supportVm,
    EmergencyContactViewModel? contactVm,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: authVm ?? AuthViewModel(authRepo),
        ),
        ChangeNotifierProvider.value(
          value: profileVm ?? RiderProfileViewModel(riderRepo: riderRepo),
        ),
        ChangeNotifierProvider.value(
          value: bookingVm ?? RideBookingViewModel(rideRepo: rideRepo),
        ),
        ChangeNotifierProvider.value(
          value: activeRideVm ?? ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime),
        ),
        ChangeNotifierProvider.value(
          value: rideVm ?? RideViewModel(rideRepo),
        ),
        ChangeNotifierProvider.value(
          value: paymentVm ?? PaymentStatusViewModel(paymentRepo: paymentRepo),
        ),
        ChangeNotifierProvider.value(
          value: historyVm ?? TripHistoryViewModel(rideRepo: rideRepo),
        ),
        ChangeNotifierProvider.value(
          value: ratingVm ?? RatingViewModel(ratingsRepo: ratingsRepo),
        ),
        ChangeNotifierProvider.value(
          value: supportVm ?? SupportViewModel(supportRepo: supportRepo),
        ),
        ChangeNotifierProvider.value(
          value: contactVm ?? EmergencyContactViewModel(supportRepo: supportRepo),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: home,
      ),
    );
  }

  group('AuthScreen Widget Tests', () {
    testWidgets('renders mobile input and transitions to OTP verification step', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.requestOtp,
        {'success': true, 'otp': '123456'},
      );

      await tester.pumpWidget(buildTestApp(const AuthScreen()));
      await tester.pump();

      expect(find.text('Enter your mobile'), findsOneWidget);
      expect(find.text('CabApp'), findsOneWidget);
      expect(find.text('Driver-First Mobility'), findsOneWidget);
      expect(find.text('Send Code'), findsOneWidget);

      // Enter phone number
      final phoneField = find.byType(TextField).first;
      await tester.enterText(phoneField, '+2348012345678');
      await tester.pump();

      // Tap Send Code
      await tester.tap(find.text('Send Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should now display OTP verification step
      expect(find.text('Verify Phone'), findsOneWidget);
      expect(find.textContaining('+2348012345678'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
    });
  });

  group('HomeMapScreen Widget Tests', () {
    testWidgets('renders map screen with pickup, destination, fare categories, and drawer navigation', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.getFareEstimatesAll,
        [
          {
            'vehicle_category': 'ECONOMY',
            'category_name': 'Economy Hatchback',
            'base_fare': 800.0,
            'distance_fare': 600.0,
            'time_fare': 100.0,
            'subtotal': 1500.0,
            'total_fare': 1500.0,
            'currency': 'NGN',
            'distance_km': 4.5,
            'estimated_duration_mins': 12.0,
          },
          {
            'vehicle_category': 'COMFORT',
            'category_name': 'Comfort Sedan',
            'base_fare': 1200.0,
            'distance_fare': 880.0,
            'time_fare': 180.0,
            'subtotal': 2260.0,
            'total_fare': 2260.0,
            'currency': 'NGN',
            'distance_km': 4.5,
            'estimated_duration_mins': 12.0,
          },
          {
            'vehicle_category': 'EXECUTIVE',
            'category_name': 'Executive SUV',
            'base_fare': 2500.0,
            'distance_fare': 1500.0,
            'time_fare': 500.0,
            'subtotal': 4500.0,
            'total_fare': 4500.0,
            'currency': 'NGN',
            'distance_km': 4.5,
            'estimated_duration_mins': 12.0,
          }
        ],
      );

      await tester.pumpWidget(buildTestApp(const HomeMapScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header & Addresses
      expect(find.text('CabApp'), findsWidgets);
      expect(find.text('Victoria Island (Adeola Odeku)'), findsOneWidget);
      expect(find.text('Lekki Phase 1 (Admiralty Way)'), findsOneWidget);

      // Categories
      expect(find.text('Economy Hatchback'), findsOneWidget);
      expect(find.text('Comfort Sedan'), findsOneWidget);
      expect(find.text('Executive SUV'), findsOneWidget);

      // Confirm button with price
      expect(find.textContaining('Confirm Economy Hatchback • ₦1500'), findsOneWidget);

      // Open drawer
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Trip History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Emergency Contacts & SOS'), findsOneWidget);
      expect(find.text('Support Desk'), findsOneWidget);
    });
  });

  group('ActiveRideScreen Widget Tests', () {
    testWidgets('renders SEARCHING state with finding ride banner and cancel button', (tester) async {
      final activeRideVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final searchingRide = RideModel.fromJson({
        'name': 'RD-2026-0001',
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
      activeRideVm.setActiveRide(searchingRide);

      await tester.pumpWidget(buildTestApp(const ActiveRideScreen(), activeRideVm: activeRideVm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Searching for Drivers...'), findsOneWidget);
      expect(find.text('Broadcasting to nearby verified drivers'), findsOneWidget);
      expect(find.text('Searching for Driver'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('₦1500.00'), findsOneWidget);

      // Clean up timer
      activeRideVm.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders ACCEPTED state with driver details, plate, and 4-digit start OTP PIN', (tester) async {
      final activeRideVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
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
      });

      final acceptedRide = RideModel.fromJson({
        'name': 'RD-2026-0001',
        'rider': 'RDR-001',
        'status': 'DRIVER_ACCEPTED',
        'pickup_address': 'Marina, Lagos',
        'pickup_lat': 6.4531,
        'pickup_lng': 3.4328,
        'destination_address': 'Ikoyi, Lagos',
        'destination_lat': 6.4500,
        'destination_lng': 3.4500,
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
        'start_otp': '7412',
        'driver_details': driver.toJson(),
      });
      activeRideVm.setActiveRide(acceptedRide);

      await tester.pumpWidget(buildTestApp(const ActiveRideScreen(), activeRideVm: activeRideVm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Driver En Route to Pickup'), findsOneWidget);
      expect(find.text('Emeka Okafor'), findsOneWidget);
      expect(find.text('Navy Blue Toyota Corolla • LAG-889-AA'), findsOneWidget);
      expect(find.text('TRIP START PIN'), findsOneWidget);
      expect(find.text('7412'), findsOneWidget);
    });

    testWidgets('renders TRIP_STARTED state with in-progress heading and floating SOS button', (tester) async {
      final activeRideVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
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
      });

      final startedRide = RideModel.fromJson({
        'name': 'RD-2026-0001',
        'rider': 'RDR-001',
        'status': 'TRIP_STARTED',
        'pickup_address': 'Marina, Lagos',
        'destination_address': 'Ikoyi, Lagos',
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
        'driver_details': driver.toJson(),
      });
      activeRideVm.setActiveRide(startedRide);

      await tester.pumpWidget(buildTestApp(const ActiveRideScreen(), activeRideVm: activeRideVm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Trip In Progress'), findsOneWidget);
      expect(find.text('Heading to destination safely'), findsOneWidget);
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
    });

    testWidgets('renders TRIP_COMPLETED state with completion banner and settlement prompt', (tester) async {
      final activeRideVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
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
      });

      final completedRide = RideModel.fromJson({
        'name': 'RD-2026-0001',
        'rider': 'RDR-001',
        'status': 'TRIP_COMPLETED',
        'pickup_address': 'Marina, Lagos',
        'destination_address': 'Ikoyi, Lagos',
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
        'driver_details': driver.toJson(),
      });
      activeRideVm.setActiveRide(completedRide);

      await tester.pumpWidget(buildTestApp(const ActiveRideScreen(), activeRideVm: activeRideVm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Trip Completed'), findsOneWidget);
      expect(find.text('Arrived at Destination'), findsOneWidget);
      expect(find.text('Rate Driver'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
    });
  });

  group('PaymentStatusDialog Widget Tests', () {
    testWidgets('renders payment options, dispute toggle, and confirmation button', (tester) async {
      final paymentVm = PaymentStatusViewModel(paymentRepo: paymentRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PaymentStatusDialog(
              rideId: 'RD-2026-0001',
              amount: 3500.0,
              paymentVm: paymentVm,
              onConfirmed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Direct Payment'), findsOneWidget);
      expect(find.text('100% P2P settlement to driver'), findsOneWidget);
      expect(find.text('₦3500.00'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('BANK TRANSFER'), findsOneWidget);
      expect(find.text('POS'), findsOneWidget);
      expect(find.text('OTHER'), findsOneWidget);
      expect(find.text('Confirm Payment Made'), findsOneWidget);

      // Tap Dispute Payment
      expect(find.text('Dispute Payment'), findsOneWidget);
      await tester.tap(find.text('Dispute Payment'));
      await tester.pump();

      expect(find.text('Submit Dispute'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('RatingDialog Widget Tests', () {
    testWidgets('renders 5 stars, compliment chips, review input, and submit button', (tester) async {
      final ratingVm = RatingViewModel(ratingsRepo: ratingsRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: RatingDialog(
              rideId: 'RD-2026-0001',
              driverName: 'Emeka Okafor',
              ratingVm: ratingVm,
              onSubmitted: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Rate Your Trip'), findsOneWidget);
      expect(find.text('How was your trip with Emeka Okafor?'), findsOneWidget);
      expect(find.text('Safe driving'), findsOneWidget);
      expect(find.text('Polite driver'), findsOneWidget);
      expect(find.text('Clean vehicle'), findsOneWidget);
      expect(find.text('Submit Rating'), findsOneWidget);

      // Tap a compliment chip
      await tester.tap(find.text('Safe driving'));
      await tester.pump();
      expect(ratingVm.selectedTags.contains('Safe driving'), isTrue);
    });
  });

  group('TripHistoryScreen Widget Tests', () {
    testWidgets('renders filter chips and loads trip history list', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.getRide,
        [
          {
            'name': 'RD-100',
            'status': 'TRIP_COMPLETED',
            'pickup_address': '14 Marina Street, Lagos Island',
            'destination_address': 'Admiralty Way, Lekki',
            'vehicle_category': 'ECONOMY',
            'final_fare': 2800.0,
            'creation': '2026-09-12 14:30:00',
          },
          {
            'name': 'RD-101',
            'status': 'CANCELLED_BY_RIDER',
            'pickup_address': 'MMA2 Domestic Airport',
            'destination_address': 'Sheraton Hotel, Ikeja',
            'vehicle_category': 'COMFORT',
            'final_fare': 0.0,
            'creation': '2026-09-11 09:15:00',
          },
        ],
      );

      final historyVm = TripHistoryViewModel(rideRepo: rideRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TripHistoryScreen(historyVm: historyVm),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Trip History'), findsOneWidget);
      expect(find.text('All Trips'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Trips in list
      expect(find.text('Admiralty Way, Lekki'), findsOneWidget);
      expect(find.text('₦2800.00'), findsOneWidget);

      // Filter by Cancelled
      await tester.tap(find.text('Cancelled'));
      await tester.pump();

      expect(find.text('Sheraton Hotel, Ikeja'), findsOneWidget);
      expect(find.text('Admiralty Way, Lekki'), findsNothing);
    });
  });

  group('RiderProfileScreen Widget Tests', () {
    testWidgets('renders rider details, stats, and safety shortcut actions', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.getProfile,
        {
          'name': 'RDR-001',
          'user': 'amina@cabapp.ng',
          'phone_number': '+2348012345678',
          'first_name': 'Amina',
          'last_name': 'Bello',
          'rating': 4.95,
          'total_trips': 24,
          'status': 'ACTIVE',
        },
      );

      final profileVm = RiderProfileViewModel(riderRepo: riderRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RiderProfileScreen(profileVm: profileVm),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Rider Profile'), findsOneWidget);
      expect(find.text('Amina Bello'), findsOneWidget);
      expect(find.text('+2348012345678'), findsWidgets);
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('(24 trips)'), findsOneWidget);
      expect(find.text('Emergency Contacts & SOS'), findsOneWidget);
      expect(find.text('Help & Support Desk'), findsOneWidget);
    });
  });

  group('EmergencyContactsScreen Widget Tests', () {
    testWidgets('renders safety banner, primary contact badge, and add button', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.getMyEmergencyContacts,
        [
          {
            'name': 'EMG-01',
            'contact_name': 'Hassan Bello',
            'phone': '+2348099998888',
            'relationship': 'Brother',
            'is_primary': 1,
          }
        ],
      );

      await tester.pumpWidget(buildTestApp(const EmergencyContactsScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Rider Safety & SOS'), findsOneWidget);
      expect(find.text('Hassan Bello'), findsOneWidget);
      expect(find.text('+2348099998888 • Brother'), findsOneWidget);
      expect(find.text('PRIMARY'), findsOneWidget);
      expect(find.text('Add Emergency Contact'), findsOneWidget);
    });
  });

  group('SupportScreen Widget Tests', () {
    testWidgets('renders 24/7 hotline, category selection, and ticket desk', (tester) async {
      mockApi.setResponse(
        ApiEndpoints.getTickets,
        [
          {
            'name': 'TCK-001',
            'subject': 'Item left in car',
            'category': 'RIDE_ISSUE',
            'description': 'Left my umbrella on the back seat',
            'status': 'OPEN',
            'created_at': '2026-09-13 10:00:00',
          }
        ],
      );

      await tester.pumpWidget(buildTestApp(const SupportScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Support & Safety'), findsOneWidget);
      expect(find.text('24/7 Safety & Dispatch Desk'), findsOneWidget);
      expect(find.text('Submit Ticket'), findsOneWidget);
      expect(find.text('Item left in car'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
    });
  });
}

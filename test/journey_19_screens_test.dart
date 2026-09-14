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
import 'package:rider_app/data/models/fare_estimate_model.dart';
import 'package:rider_app/data/models/ride_model.dart';
import 'package:rider_app/data/repositories/auth_repository.dart';
import 'package:rider_app/data/repositories/payment_repository.dart';
import 'package:rider_app/data/repositories/ratings_repository.dart';
import 'package:rider_app/data/repositories/ride_repository.dart';
import 'package:rider_app/data/repositories/rider_repository.dart';
import 'package:rider_app/data/repositories/support_repository.dart';
import 'package:rider_app/presentation/routes/app_routes.dart';
import 'package:rider_app/presentation/screens/active_trip_screen.dart';
import 'package:rider_app/presentation/screens/confirm_ride_screen.dart';
import 'package:rider_app/presentation/screens/destination_screen.dart';
import 'package:rider_app/presentation/screens/driver_arriving_screen.dart';
import 'package:rider_app/presentation/screens/driver_assigned_screen.dart';
import 'package:rider_app/presentation/screens/fare_estimate_screen.dart';
import 'package:rider_app/presentation/screens/home_map_screen.dart';
import 'package:rider_app/presentation/screens/location_permission_screen.dart';
import 'package:rider_app/presentation/screens/login_screen.dart';
import 'package:rider_app/presentation/screens/otp_screen.dart';
import 'package:rider_app/presentation/screens/payment_screen.dart';
import 'package:rider_app/presentation/screens/pickup_screen.dart';
import 'package:rider_app/presentation/screens/rating_screen.dart';
import 'package:rider_app/presentation/screens/registration_screen.dart';
import 'package:rider_app/presentation/screens/rider_profile_screen.dart';
import 'package:rider_app/presentation/screens/searching_screen.dart';
import 'package:rider_app/presentation/screens/splash_screen.dart';
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

  Widget buildApp(Widget screen, {
    AuthViewModel? authVm,
    RideBookingViewModel? bookingVm,
    ActiveRideViewModel? activeRideVm,
    RideViewModel? rideVm,
    PaymentStatusViewModel? paymentVm,
    RatingViewModel? ratingVm,
    RiderProfileViewModel? profileVm,
    SupportViewModel? supportVm,
    TripHistoryViewModel? historyVm,
    EmergencyContactViewModel? contactVm,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authVm ?? AuthViewModel(authRepo)),
        ChangeNotifierProvider.value(value: bookingVm ?? RideBookingViewModel(rideRepo: rideRepo)),
        ChangeNotifierProvider.value(value: activeRideVm ?? ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime)),
        ChangeNotifierProvider.value(value: rideVm ?? RideViewModel(rideRepo)),
        ChangeNotifierProvider.value(value: paymentVm ?? PaymentStatusViewModel(paymentRepo: paymentRepo)),
        ChangeNotifierProvider.value(value: ratingVm ?? RatingViewModel(ratingsRepo: ratingsRepo)),
        ChangeNotifierProvider.value(value: profileVm ?? RiderProfileViewModel(riderRepo: riderRepo)),
        ChangeNotifierProvider.value(value: supportVm ?? SupportViewModel(supportRepo: supportRepo)),
        ChangeNotifierProvider.value(value: historyVm ?? TripHistoryViewModel(rideRepo: rideRepo)),
        ChangeNotifierProvider.value(value: contactVm ?? EmergencyContactViewModel(supportRepo: supportRepo)),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: screen,
      ),
    );
  }

  group('All 19 Screens End-to-End Coverage', () {
    testWidgets('Screen 1 (Splash) renders branding and LaunchGird label', (tester) async {
      await tester.pumpWidget(buildApp(const SplashScreen()));
      await tester.pump();

      expect(find.text('CabApp'), findsOneWidget);
      expect(find.text('Driver-First Mobility'), findsOneWidget);
      expect(find.text('A product by LaunchGird Limited'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen 2 (Login) renders phone number form and send code button', (tester) async {
      await tester.pumpWidget(buildApp(const LoginScreen()));
      await tester.pump();

      expect(find.text('Enter your mobile'), findsOneWidget);
      expect(find.text('+234'), findsOneWidget);
      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('Screen 3 (OTP) renders pin verification and resend countdown', (tester) async {
      await tester.pumpWidget(buildApp(const OtpScreen(phoneNumber: '+2348012345678')));
      await tester.pump();

      expect(find.text('Verify Phone'), findsOneWidget);
      expect(find.textContaining('+2348012345678'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(find.textContaining('Resend code in'), findsOneWidget);
    });

    testWidgets('Screen 4 (Registration) renders name and email inputs', (tester) async {
      await tester.pumpWidget(buildApp(const RegistrationScreen()));
      await tester.pump();

      expect(find.text('Create Your Profile'), findsOneWidget);
      expect(find.text('FIRST NAME'), findsOneWidget);
      expect(find.text('LAST NAME'), findsOneWidget);
      expect(find.text('Complete Registration'), findsOneWidget);
    });

    testWidgets('Screen 5 (Home) renders map canvas, popular locations, and P2P badge', (tester) async {
      mockApi.setResponse(ApiEndpoints.getFareEstimatesAll, [
        {
          'vehicle_category': 'ECONOMY',
          'category_name': 'Economy Sedan',
          'base_fare': 800.0,
          'distance_fare': 600.0,
          'time_fare': 100.0,
          'subtotal': 1500.0,
          'total_fare': 1500.0,
          'currency': 'NGN',
          'distance_km': 4.5,
          'estimated_duration_mins': 12.0,
        }
      ]);

      await tester.pumpWidget(buildApp(const HomeMapScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CabApp'), findsWidgets);
      expect(find.textContaining('100% Direct P2P Settlement'), findsOneWidget);
    });

    testWidgets('Screen 6 (Location Permission) renders value proposition and buttons', (tester) async {
      await tester.pumpWidget(buildApp(const LocationPermissionScreen()));
      await tester.pump();

      expect(find.text('Enable Location Access'), findsOneWidget);
      expect(find.text('Allow Location Access'), findsOneWidget);
      expect(find.text('Set Location Manually'), findsOneWidget);
    });

    testWidgets('Screen 7 (Pickup) renders Lagos hubs and GPS action', (tester) async {
      await tester.pumpWidget(buildApp(const PickupScreen()));
      await tester.pump();

      expect(find.text('Set Pickup Spot'), findsOneWidget);
      expect(find.text('Use current GPS location'), findsOneWidget);
      expect(find.text('Victoria Island (Adeola Odeku)'), findsOneWidget);
    });

    testWidgets('Screen 8 (Destination) renders destination search and destinations', (tester) async {
      await tester.pumpWidget(buildApp(const DestinationScreen()));
      await tester.pump();

      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('Lekki Phase 1 (Admiralty Way)'), findsOneWidget);
      expect(find.text('Murtala Muhammed Airport (MMA2)'), findsOneWidget);
    });

    testWidgets('Screen 9 (Fare Estimate) renders category options and continue CTA', (tester) async {
      final bookingVm = RideBookingViewModel(rideRepo: rideRepo);
      bookingVm.setPickup('Victoria Island', 6.4281, 3.4219);
      bookingVm.setDestination('Lekki Phase 1', 6.4474, 3.4723);

      mockApi.setResponse(ApiEndpoints.getFareEstimatesAll, [
        {
          'vehicle_category': 'ECONOMY',
          'category_name': 'Economy Hatchback',
          'base_fare': 800.0,
          'distance_fare': 600.0,
          'time_fare': 100.0,
          'subtotal': 1500.0,
          'total_fare': 1500.0,
          'currency': 'NGN',
          'distance_km': 5.0,
          'estimated_duration_mins': 15.0,
        },
        {
          'vehicle_category': 'COMFORT',
          'category_name': 'Comfort Sedan',
          'base_fare': 1200.0,
          'distance_fare': 800.0,
          'time_fare': 200.0,
          'subtotal': 2200.0,
          'total_fare': 2200.0,
          'currency': 'NGN',
          'distance_km': 5.0,
          'estimated_duration_mins': 15.0,
        },
      ]);
      await bookingVm.fetchFareEstimates();

      await tester.pumpWidget(buildApp(const FareEstimateScreen(), bookingVm: bookingVm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Fare Estimate'), findsOneWidget);
      expect(find.text('Economy Hatchback'), findsOneWidget);
      expect(find.text('Comfort Sedan'), findsOneWidget);
      expect(find.text('₦1500.00'), findsOneWidget);
      expect(find.text('₦2200.00'), findsOneWidget);
      expect(find.textContaining('Continue with'), findsOneWidget);
    });

    testWidgets('Screen 10 (Confirm Ride) renders route recap and confirm booking button', (tester) async {
      final bookingVm = RideBookingViewModel(rideRepo: rideRepo);
      bookingVm.setPickup('Marina, Lagos', 6.4531, 3.4328);
      bookingVm.setDestination('Ikoyi, Lagos', 6.4500, 3.4500);
      bookingVm.selectCategory(
        const FareEstimateModel(
          vehicleCategory: 'ECONOMY',
          categoryName: 'Economy Sedan',
          baseFare: 800.0,
          distanceRate: 100.0,
          timeRate: 20.0,
          minimumFare: 800.0,
          estimatedDurationMins: 15.0,
          distanceKm: 5.0,
          totalFare: 1500.0,
        ),
      );

      await tester.pumpWidget(buildApp(const ConfirmRideScreen(), bookingVm: bookingVm));
      await tester.pump();

      expect(find.text('Confirm Ride'), findsOneWidget);
      expect(find.text('Marina, Lagos'), findsOneWidget);
      expect(find.text('Ikoyi, Lagos'), findsOneWidget);
      expect(find.text('Base Fare'), findsOneWidget);
      expect(find.text('Confirm & Request Economy Sedan'), findsOneWidget);
    });

    testWidgets('Screen 11 (Searching) renders pulsing animation and cancel request button', (tester) async {
      final activeVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final ride = RideModel.fromJson({
        'name': 'RD-2026-0011',
        'rider': 'RDR-001',
        'status': 'SEARCHING',
        'pickup_address': 'Victoria Island',
        'pickup_lat': 6.4281,
        'pickup_lng': 3.4219,
        'destination_address': 'Lekki Phase 1',
        'destination_lat': 6.4474,
        'destination_lng': 3.4723,
        'vehicle_category': 'ECONOMY',
        'total_fare': 1500.0,
      });
      activeVm.setActiveRide(ride);

      await tester.pumpWidget(buildApp(const SearchingScreen(), activeRideVm: activeVm));
      await tester.pump();

      expect(find.text('Searching for Driver'), findsOneWidget);
      expect(find.text('Connecting with Drivers...'), findsOneWidget);
      expect(find.text('Cancel Request'), findsOneWidget);

      activeVm.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen 12 (Driver Assigned) renders driver match and 4-digit PIN', (tester) async {
      final activeVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
        'driver': 'DRV-100',
        'driver_name': 'Babatunde Adeyemi',
        'driver_phone': '+2348033334444',
        'vehicle_make': 'Toyota',
        'vehicle_model': 'Camry',
        'vehicle_color': 'Silver',
        'license_plate': 'EKY-123-XY',
        'vehicle_category': 'ECONOMY',
        'rating': 4.92,
        'total_trips': 210,
      });

      final ride = RideModel.fromJson({
        'name': 'RD-2026-0012',
        'rider': 'RDR-001',
        'status': 'DRIVER_ASSIGNED',
        'pickup_address': 'Victoria Island',
        'destination_address': 'Lekki Phase 1',
        'vehicle_category': 'ECONOMY',
        'total_fare': 1800.0,
        'start_otp': '3951',
        'driver_details': driver.toJson(),
      });
      activeVm.setActiveRide(ride);

      await tester.pumpWidget(buildApp(const DriverAssignedScreen(), activeRideVm: activeVm));
      await tester.pump();

      expect(find.text('Driver Assigned'), findsOneWidget);
      expect(find.text('Driver Found!'), findsOneWidget);
      expect(find.text('Babatunde Adeyemi'), findsOneWidget);
      expect(find.text('EKY-123-XY'), findsOneWidget);
      expect(find.text('3951'), findsOneWidget);
      expect(find.text('Track Driver Arrival'), findsOneWidget);

      activeVm.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen 13 (Driver Arriving) renders arrival status and 4-digit PIN', (tester) async {
      final activeVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
        'driver': 'DRV-100',
        'driver_name': 'Babatunde Adeyemi',
        'driver_phone': '+2348033334444',
        'vehicle_make': 'Toyota',
        'vehicle_model': 'Camry',
        'vehicle_color': 'Silver',
        'license_plate': 'EKY-123-XY',
        'vehicle_category': 'ECONOMY',
        'rating': 4.92,
        'total_trips': 210,
      });

      final ride = RideModel.fromJson({
        'name': 'RD-2026-0013',
        'rider': 'RDR-001',
        'status': 'DRIVER_ARRIVED',
        'pickup_address': 'Victoria Island',
        'destination_address': 'Lekki Phase 1',
        'vehicle_category': 'ECONOMY',
        'total_fare': 1800.0,
        'start_otp': '3951',
        'driver_details': driver.toJson(),
      });
      activeVm.setActiveRide(ride);

      await tester.pumpWidget(buildApp(const DriverArrivingScreen(), activeRideVm: activeVm));
      await tester.pump();

      expect(find.text('Driver Has Arrived!'), findsOneWidget);
      expect(find.text('TRIP START PIN'), findsOneWidget);
      expect(find.text('3951'), findsOneWidget);
      expect(find.text('Call Driver'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);

      activeVm.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen 14 (Active Trip) renders in-progress state and floating SOS', (tester) async {
      final activeVm = ActiveRideViewModel(rideRepo: rideRepo, realtimeService: mockRealtime);
      final driver = DriverDetailsModel.fromJson({
        'driver': 'DRV-100',
        'driver_name': 'Babatunde Adeyemi',
        'license_plate': 'EKY-123-XY',
      });

      final ride = RideModel.fromJson({
        'name': 'RD-2026-0014',
        'rider': 'RDR-001',
        'status': 'TRIP_STARTED',
        'pickup_address': 'Victoria Island',
        'destination_address': 'Lekki Phase 1',
        'vehicle_category': 'ECONOMY',
        'total_fare': 1800.0,
        'driver_details': driver.toJson(),
      });
      activeVm.setActiveRide(ride);

      await tester.pumpWidget(buildApp(const ActiveTripScreen(), activeRideVm: activeVm));
      await tester.pump();

      expect(find.text('Trip In Progress'), findsOneWidget);
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.text('Arrived? Proceed to Payment'), findsOneWidget);

      activeVm.reset();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Screen 15 (Payment) renders direct settlement, methods, and confirm button', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const PaymentScreen(
            rideId: 'RD-2026-0015',
            amount: 2500.0,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Payment Due'), findsOneWidget);
      expect(find.text('Direct Driver Settlement'), findsOneWidget);
      expect(find.text('₦2500.00'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('BANK TRANSFER'), findsOneWidget);
      expect(find.text('Confirm Payment Made'), findsOneWidget);
      expect(find.text('Having issues? Raise a payment dispute'), findsOneWidget);
    });

    testWidgets('Screen 16 (Rating) renders 5-star selector, compliment chips, and submit', (tester) async {
      await tester.pumpWidget(
        buildApp(
          const RatingScreen(
            rideId: 'RD-2026-0016',
            driverName: 'Babatunde Adeyemi',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Trip Rating'), findsOneWidget);
      expect(find.text('How was your ride?'), findsOneWidget);
      expect(find.text('Trip with Babatunde Adeyemi'), findsOneWidget);
      expect(find.text('Clean vehicle'), findsOneWidget);
      expect(find.text('Submit Rating'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);
    });

    testWidgets('Screen 17 (Trip History) renders screen and list', (tester) async {
      mockApi.setResponse(ApiEndpoints.getRide, []);
      final historyVm = TripHistoryViewModel(rideRepo: rideRepo);

      await tester.pumpWidget(buildApp(TripHistoryScreen(historyVm: historyVm)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Trip History'), findsOneWidget);
    });

    testWidgets('Screen 18 (Profile) renders profile screen', (tester) async {
      mockApi.setResponse(ApiEndpoints.getProfile, {
        'name': 'RDR-001',
        'user': 'rider@test.com',
        'phone_number': '+2348011112222',
        'first_name': 'Test',
        'last_name': 'Rider',
        'rating': 4.9,
        'total_trips': 10,
        'status': 'ACTIVE',
      });
      final profileVm = RiderProfileViewModel(riderRepo: riderRepo);

      await tester.pumpWidget(buildApp(RiderProfileScreen(profileVm: profileVm)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Rider Profile'), findsOneWidget);
    });

    testWidgets('Screen 19 (Support) renders support screen', (tester) async {
      mockApi.setResponse(ApiEndpoints.getTickets, []);
      await tester.pumpWidget(buildApp(const SupportScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Support & Safety'), findsOneWidget);
      expect(find.text('24/7 Safety & Dispatch Desk'), findsOneWidget);
    });
  });
}

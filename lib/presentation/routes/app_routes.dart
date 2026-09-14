import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/active_trip_screen.dart';
import '../screens/confirm_ride_screen.dart';
import '../screens/destination_screen.dart';
import '../screens/driver_arriving_screen.dart';
import '../screens/driver_assigned_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/fare_estimate_screen.dart';
import '../screens/home_map_screen.dart';
import '../screens/location_permission_screen.dart';
import '../screens/login_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/pickup_screen.dart';
import '../screens/rating_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/rider_profile_screen.dart';
import '../screens/searching_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/support_screen.dart';
import '../screens/trip_history_screen.dart';
import '../viewmodels/rider_profile_viewmodel.dart';
import '../viewmodels/trip_history_viewmodel.dart';

/// Centralized route constants and route generator for the 19 core screens
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String registration = '/registration';
  static const String home = '/home';
  static const String locationPermission = '/location-permission';
  static const String pickup = '/pickup';
  static const String destination = '/destination';
  static const String fareEstimate = '/fare-estimate';
  static const String confirmRide = '/confirm-ride';
  static const String searching = '/searching';
  static const String driverAssigned = '/driver-assigned';
  static const String driverArriving = '/driver-arriving';
  static const String activeTrip = '/active-trip';
  static const String payment = '/payment';
  static const String rating = '/rating';
  static const String tripHistory = '/trip-history';
  static const String profile = '/profile';
  static const String support = '/support';
  static const String emergencyContacts = '/emergency-contacts';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case otp:
        final phone = settings.arguments as String? ?? '+234';
        return MaterialPageRoute(builder: (_) => OtpScreen(phoneNumber: phone));
      case registration:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeMapScreen());
      case locationPermission:
        return MaterialPageRoute(builder: (_) => const LocationPermissionScreen());
      case pickup:
        return MaterialPageRoute(builder: (_) => const PickupScreen());
      case destination:
        return MaterialPageRoute(builder: (_) => const DestinationScreen());
      case fareEstimate:
        return MaterialPageRoute(builder: (_) => const FareEstimateScreen());
      case confirmRide:
        return MaterialPageRoute(builder: (_) => const ConfirmRideScreen());
      case searching:
        return MaterialPageRoute(builder: (_) => const SearchingScreen());
      case driverAssigned:
        return MaterialPageRoute(builder: (_) => const DriverAssignedScreen());
      case driverArriving:
        return MaterialPageRoute(builder: (_) => const DriverArrivingScreen());
      case activeTrip:
        return MaterialPageRoute(builder: (_) => const ActiveTripScreen());
      case payment:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            rideId: args?['rideId'] as String?,
            amount: (args?['amount'] as num?)?.toDouble(),
          ),
        );
      case rating:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RatingScreen(
            rideId: args?['rideId'] as String?,
            driverName: args?['driverName'] as String?,
          ),
        );
      case tripHistory:
        return MaterialPageRoute(
          builder: (context) => TripHistoryScreen(
            historyVm: context.read<TripHistoryViewModel>(),
          ),
        );
      case profile:
        return MaterialPageRoute(
          builder: (context) => RiderProfileScreen(
            profileVm: context.read<RiderProfileViewModel>(),
          ),
        );
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      case emergencyContacts:
        return MaterialPageRoute(builder: (_) => const EmergencyContactsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

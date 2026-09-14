import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/services/realtime_service.dart';
import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/ratings_repository.dart';
import 'data/repositories/ride_repository.dart';
import 'data/repositories/rider_repository.dart';
import 'data/repositories/support_repository.dart';
import 'data/services/notification_client_service.dart';

import 'presentation/viewmodels/active_ride_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/emergency_contact_viewmodel.dart';
import 'presentation/viewmodels/payment_status_viewmodel.dart';
import 'presentation/viewmodels/rating_viewmodel.dart';
import 'presentation/viewmodels/ride_booking_viewmodel.dart';
import 'presentation/viewmodels/ride_viewmodel.dart';
import 'presentation/viewmodels/rider_profile_viewmodel.dart';
import 'presentation/viewmodels/support_viewmodel.dart';
import 'presentation/viewmodels/trip_history_viewmodel.dart';

import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionManager = await SessionManager.init();
  final apiClient = ApiClient(sessionManager: sessionManager);

  final authRepo = AuthRepository(apiClient: apiClient, sessionManager: sessionManager);
  final riderRepo = RiderRepository(apiClient: apiClient);
  final rideRepo = RideRepository(apiClient: apiClient);
  final paymentRepo = PaymentRepository(apiClient: apiClient);
  final ratingsRepo = RatingsRepository(apiClient: apiClient);
  final supportRepo = SupportRepository(apiClient: apiClient);

  final realtimeService = PollingRealtimeService(apiClient: apiClient);
  realtimeService.connect();

  final notificationService = NotificationClientService(apiClient: apiClient, sessionManager: sessionManager);

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionManager>.value(value: sessionManager),
        Provider<IApiClient>.value(value: apiClient),
        Provider<ApiClient>.value(value: apiClient),
        Provider<IRealtimeService>.value(value: realtimeService),
        Provider<NotificationClientService>.value(value: notificationService),
        // Repositories
        Provider<AuthRepository>.value(value: authRepo),
        Provider<RiderRepository>.value(value: riderRepo),
        Provider<RideRepository>.value(value: rideRepo),
        Provider<PaymentRepository>.value(value: paymentRepo),
        Provider<RatingsRepository>.value(value: ratingsRepo),
        Provider<SupportRepository>.value(value: supportRepo),
        // ViewModels
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => RiderProfileViewModel(riderRepo: riderRepo)),
        ChangeNotifierProvider(create: (_) => RideBookingViewModel(rideRepo: rideRepo)),
        ChangeNotifierProvider(
          create: (_) => ActiveRideViewModel(rideRepo: rideRepo, realtimeService: realtimeService),
        ),
        ChangeNotifierProvider(create: (_) => RideViewModel(rideRepo)),
        ChangeNotifierProvider(create: (_) => PaymentStatusViewModel(paymentRepo: paymentRepo)),
        ChangeNotifierProvider(create: (_) => TripHistoryViewModel(rideRepo: rideRepo)),
        ChangeNotifierProvider(create: (_) => RatingViewModel(ratingsRepo: ratingsRepo)),
        ChangeNotifierProvider(create: (_) => SupportViewModel(supportRepo: supportRepo)),
        ChangeNotifierProvider(create: (_) => EmergencyContactViewModel(supportRepo: supportRepo)),
      ],
      child: const CabAppRider(),
    ),
  );
}

class CabAppRider extends StatelessWidget {
  const CabAppRider({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CabApp Rider',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/storage/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/ride_repository.dart';
import 'data/services/notification_client_service.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/home_map_screen.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/ride_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionManager = await SessionManager.init();
  final apiClient = ApiClient(sessionManager: sessionManager);

  final authRepo = AuthRepository(apiClient: apiClient, sessionManager: sessionManager);
  final rideRepo = RideRepository(apiClient: apiClient);
  final notificationService = NotificationClientService(apiClient: apiClient, sessionManager: sessionManager);

  runApp(
    MultiProvider(
      providers: [
        Provider<SessionManager>.value(value: sessionManager),
        Provider<ApiClient>.value(value: apiClient),
        Provider<NotificationClientService>.value(value: notificationService),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => RideViewModel(rideRepo)),
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
      home: Consumer<AuthViewModel>(
        builder: (context, authVm, _) {
          if (authVm.isAuthenticated) {
            return const HomeMapScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

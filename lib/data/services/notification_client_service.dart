import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_manager.dart';

class NotificationClientService {
  final ApiClient apiClient;
  final SessionManager sessionManager;

  NotificationClientService({
    required this.apiClient,
    required this.sessionManager,
  });

  Future<void> registerDeviceToken({
    required String fcmToken,
    String platform = 'Android',
    String? deviceId,
  }) async {
    await sessionManager.saveFcmToken(fcmToken);

    if (sessionManager.isAuthenticated) {
      try {
        await apiClient.post(
          ApiEndpoints.registerDevice,
          body: {
            'token': fcmToken,
            'platform': platform,
            'app_type': 'Rider',
            'device_id': deviceId,
          },
        );
      } catch (_) {
        // Non-fatal: token is safely stored locally and can retry on reconnect
      }
    }
  }

  Future<void> unregisterDeviceToken() async {
    final token = sessionManager.fcmToken;
    if (token != null && sessionManager.isAuthenticated) {
      try {
        await apiClient.post(
          ApiEndpoints.unregisterDevice,
          body: {'token': token},
        );
      } catch (_) {}
    }
  }
}

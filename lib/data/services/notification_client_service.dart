import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/notifications/models/notification_channel.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/session_manager.dart';

class NotificationClientService {
  final ApiClient apiClient;
  final SessionManager sessionManager;
  Timer? _pollTimer;
  final Set<String> _deliveredEventIds = {};
  bool _tokenRegistered = false;

  NotificationClientService({
    required this.apiClient,
    required this.sessionManager,
  });

  bool get _isTestEnv => WidgetsBinding.instance.runtimeType.toString().contains('Test');

  void startLivePushSync() {
    if (_isTestEnv || _pollTimer != null) return;
    NotificationService.instance.initialize().then((_) {
      final fcmToken = NotificationService.instance.fcmHandler.currentToken;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        sessionManager.saveFcmToken(fcmToken);
      }
      _ensureDeviceTokenRegistered();
    }).catchError((_) {
      _ensureDeviceTokenRegistered();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollPushNotifications();
    });
  }

  void stopLivePushSync() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> ensureDeviceTokenRegistered({bool force = false}) async {
    if ((_tokenRegistered && !force) || !sessionManager.isAuthenticated) return;
    final token = sessionManager.fcmToken ??
        'fcm_android_rider_${sessionManager.phone?.replaceAll('+', '') ?? DateTime.now().millisecondsSinceEpoch}';
    await registerDeviceToken(fcmToken: token, platform: 'Android');
    _tokenRegistered = true;
  }

  Future<void> _pollPushNotifications() async {
    if (!sessionManager.isAuthenticated) return;
    if (!_tokenRegistered) {
      await ensureDeviceTokenRegistered();
    }
    try {
      final response = await apiClient.get(
        '/api/method/mobility.api.notification.get_my_notifications',
        queryParams: {'limit': '10'},
      );
      final data = response['data'] ?? (response['message'] is Map ? response['message']['data'] : null);
      if (data is List && data.isNotEmpty) {
        final isInitialSeed = _deliveredEventIds.isEmpty;
        for (final item in data.reversed) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final eventId = map['event_id']?.toString() ?? '';
            if (eventId.isEmpty || _deliveredEventIds.contains(eventId)) continue;
            _deliveredEventIds.add(eventId);

            // Deliver if runtime event OR if timestamp is within the last 180 seconds
            bool shouldDeliver = !isInitialSeed;
            if (isInitialSeed && map['timestamp'] != null) {
              try {
                final ts = DateTime.parse(map['timestamp'].toString());
                if (DateTime.now().difference(ts).inSeconds.abs() < 180) {
                  shouldDeliver = true;
                }
              } catch (_) {}
            }

            if (shouldDeliver) {
              NotificationService.instance.handleIncomingPayload(
                {
                  'message_id': eventId,
                  'notification': {
                    'title': map['title'] ?? 'CabApp Alert',
                    'body': map['body'] ?? '',
                  },
                  'data': {
                    ...(map['data'] is Map ? Map<String, dynamic>.from(map['data']) : {}),
                    'event': map['event'] ?? 'ride_request',
                    'event_id': eventId,
                  },
                },
                NotificationChannel.fcm,
              );
            }
          }
        }
      }
    } catch (_) {}
  }

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
    _tokenRegistered = false;
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

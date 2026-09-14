import 'dart:async';
import '../network/api_client.dart';
import 'handlers/fcm_channel_handler.dart';
import 'handlers/in_app_realtime_handler.dart';
import 'interfaces/i_notification_service.dart';
import 'models/app_notification.dart';
import 'models/notification_channel.dart';
import 'models/notification_event.dart';

/// Unified NotificationService implementation managing multi-channel delivery,
/// token lifecycle, and event deduplication.
class NotificationService implements INotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService();

  final IApiClient? apiClient;
  final FCMChannelHandler fcmHandler;
  final InAppRealtimeHandler realtimeHandler;

  final _notificationController = StreamController<AppNotification>.broadcast();
  final _eventController = StreamController<NotificationEvent>.broadcast();

  final List<AppNotification> _notifications = [];
  final Set<String> _seenEventIds = {};

  String? _activeToken;

  NotificationService({
    this.apiClient,
    FCMChannelHandler? customFcmHandler,
    InAppRealtimeHandler? customRealtimeHandler,
  })  : fcmHandler = customFcmHandler ?? FCMChannelHandler(),
        realtimeHandler = customRealtimeHandler ?? InAppRealtimeHandler() {
    _wireHandlers();
  }

  void _wireHandlers() {
    fcmHandler.setNotificationListener(_processNotification);
    realtimeHandler.setNotificationListener(_processNotification);
  }

  void _processNotification(AppNotification notification) {
    // Deduplication check
    if (notification.id.isNotEmpty && _seenEventIds.contains(notification.id)) {
      return;
    }
    _seenEventIds.add(notification.id);

    _notifications.insert(0, notification);
    _notificationController.add(notification);
    _eventController.add(notification.event);
  }

  @override
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  @override
  Stream<NotificationEvent> get eventStream => _eventController.stream;

  @override
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  @override
  String? get activeDeviceToken => _activeToken;

  @override
  Future<void> initialize() async {
    await fcmHandler.initialize();
    await realtimeHandler.initialize();
  }

  @override
  Future<void> registerDeviceToken(String token) async {
    _activeToken = token;
    fcmHandler.updateToken(token);

    if (apiClient != null) {
      try {
        await apiClient!.post(
          '/api/method/mobility.api.notification.register_device',
          body: {
            'token': token,
            'platform': 'Android',
            'app_type': 'Rider',
          },
        );
      } catch (_) {
        // Log non-fatal registration retry
      }
    }
  }

  @override
  Future<void> unregisterDeviceToken() async {
    final token = _activeToken;
    _activeToken = null;
    if (token != null && apiClient != null) {
      try {
        await apiClient!.post(
          '/api/method/mobility.api.notification.unregister_device',
          body: {'token': token},
        );
      } catch (_) {
        // Silently ignore logout unregister failures
      }
    }
  }

  @override
  void handleIncomingPayload(Map<String, dynamic> rawPayload, NotificationChannel channel) {
    if (channel == NotificationChannel.fcm) {
      fcmHandler.simulateIncomingPush(rawPayload);
    } else {
      realtimeHandler.handleRealtimeEnvelope(rawPayload);
    }
  }

  @override
  void markAsRead(String id) {
    for (final notif in _notifications) {
      if (notif.id == id) {
        notif.isRead = true;
        break;
      }
    }
  }

  @override
  void clearAll() {
    _notifications.clear();
    _seenEventIds.clear();
  }

  @override
  void dispose() {
    fcmHandler.dispose();
    realtimeHandler.dispose();
    _notificationController.close();
    _eventController.close();
  }
}

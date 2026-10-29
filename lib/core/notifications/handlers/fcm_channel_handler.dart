import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../models/notification_channel.dart';
import 'i_notification_channel_handler.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

/// Decoupled FCM Channel Handler.
///
/// Encapsulates all Firebase Cloud Messaging interactions.
/// Business logic and UI never talk to FirebaseMessaging directly.
class FCMChannelHandler implements INotificationChannelHandler {
  void Function(AppNotification notification)? _listener;
  String? _currentToken;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  NotificationChannel get channel => NotificationChannel.fcm;

  String? get currentToken => _currentToken;

  @override
  void setNotificationListener(void Function(AppNotification notification) listener) {
    _listener = listener;
  }

  @override
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
      }

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
      });

      _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final payload = _convertRemoteMessage(message);
        final notif = AppNotification.fromFcmPayload(payload);
        _listener?.call(notif);
      });

      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final payload = _convertRemoteMessage(message);
        final notif = AppNotification.fromFcmPayload(payload);
        _listener?.call(notif);
      });
    } catch (_) {
      // Non-fatal fallback for unit tests or environments without Google Play Services
    }
  }

  Map<String, dynamic> _convertRemoteMessage(RemoteMessage message) {
    return {
      'message_id': message.messageId,
      'notification': {
        'title': message.notification?.title,
        'body': message.notification?.body,
      },
      'data': message.data,
    };
  }

  /// Simulate or ingest an incoming push notification payload from FCM
  void simulateIncomingPush(Map<String, dynamic> rawPayload) {
    final notif = AppNotification.fromFcmPayload(rawPayload);
    _listener?.call(notif);
  }

  void updateToken(String token) {
    _currentToken = token;
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _listener = null;
  }
}

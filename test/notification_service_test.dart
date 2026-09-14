import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/notifications/notification_service_exports.dart';

void main() {
  group('Notification Domain Models', () {
    test('NotificationEvent maps all 10 domain events accurately', () {
      expect(NotificationEvent.fromString('ride_request'), NotificationEvent.rideRequest);
      expect(NotificationEvent.fromString('ride_offered'), NotificationEvent.rideRequest);
      expect(NotificationEvent.fromString('driver_accepted'), NotificationEvent.driverAccepted);
      expect(NotificationEvent.fromString('driver_arriving'), NotificationEvent.driverArriving);
      expect(NotificationEvent.fromString('driver_arrived'), NotificationEvent.driverArriving);
      expect(NotificationEvent.fromString('trip_started'), NotificationEvent.tripStarted);
      expect(NotificationEvent.fromString('trip_completed'), NotificationEvent.tripCompleted);
      expect(NotificationEvent.fromString('payment_pending'), NotificationEvent.paymentPending);
      expect(NotificationEvent.fromString('payment_confirmed'), NotificationEvent.paymentConfirmed);
      expect(NotificationEvent.fromString('payment_settled'), NotificationEvent.paymentConfirmed);
      expect(NotificationEvent.fromString('subscription_expiring'), NotificationEvent.subscriptionExpiring);
      expect(NotificationEvent.fromString('subscription_expired'), NotificationEvent.subscriptionExpired);
      expect(NotificationEvent.fromString('support_update'), NotificationEvent.supportUpdate);
      expect(NotificationEvent.fromString('unknown_foo'), NotificationEvent.unknown);
    });

    test('AppNotification parses FCM payload and preserves metadata', () {
      final fcmRaw = {
        'message_id': 'fcm_msg_001',
        'notification': {
          'title': 'Driver On The Way!',
          'body': 'Adewale (LND-456-XY) has accepted your ride.',
        },
        'data': {
          'event': 'driver_accepted',
          'ride_id': 'RIDE-999',
          'driver_id': 'DRV-101',
          'start_otp': '7890',
        },
        'sound': 'default',
        'priority': 'high',
      };

      final notif = AppNotification.fromFcmPayload(fcmRaw);
      expect(notif.id, 'fcm_msg_001');
      expect(notif.event, NotificationEvent.driverAccepted);
      expect(notif.channel, NotificationChannel.fcm);
      expect(notif.title, 'Driver On The Way!');
      expect(notif.body, contains('Adewale'));
      expect(notif.data['start_otp'], '7890');
      expect(notif.priority, 'high');
      expect(notif.isRead, false);
    });

    test('AppNotification parses In-App Realtime envelope', () {
      final rtEnvelope = {
        'event_id': 'rt_event_002',
        'notification_event': 'payment_confirmed',
        'notification': {
          'title': 'Payment Confirmed',
          'body': 'Fare of ₦3,500.00 confirmed.',
        },
        'payload': {
          'ride_id': 'RIDE-999',
          'fare': '3500.00',
        },
      };

      final notif = AppNotification.fromRealtimePayload(rtEnvelope);
      expect(notif.id, 'rt_event_002');
      expect(notif.event, NotificationEvent.paymentConfirmed);
      expect(notif.channel, NotificationChannel.inAppRealtime);
      expect(notif.title, 'Payment Confirmed');
      expect(notif.data['fare'], '3500.00');
    });

    test('AppNotification serializes and deserializes cleanly to JSON', () {
      final notif = AppNotification(
        id: 'notif_json_001',
        event: NotificationEvent.supportUpdate,
        channel: NotificationChannel.fcm,
        title: 'Support Ticket #100',
        body: 'Your ticket has been resolved.',
        data: {'ticket_id': '100', 'status': 'RESOLVED'},
      );

      final json = notif.toJson();
      expect(json['id'], 'notif_json_001');
      expect(json['event'], 'support_update');
      expect(json['channel'], 'fcm');

      final reconstructed = AppNotification.fromJson(json);
      expect(reconstructed.id, notif.id);
      expect(reconstructed.event, NotificationEvent.supportUpdate);
      expect(reconstructed.data['ticket_id'], '100');
    });
  });

  group('Master NotificationService Logic', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('Broadcasting across FCM and Realtime channels with event stream', () async {
      final List<AppNotification> captured = [];
      final List<NotificationEvent> capturedEvents = [];

      final sub1 = service.notificationStream.listen(captured.add);
      final sub2 = service.eventStream.listen(capturedEvents.add);

      // 1. Simulate FCM push
      service.handleIncomingPayload({
        'message_id': 'evt_01',
        'data': {
          'event': 'trip_started',
          'title': 'Trip In Transit',
          'body': 'Destination: Victoria Island',
        },
      }, NotificationChannel.fcm);

      // 2. Simulate Realtime envelope
      service.handleIncomingPayload({
        'event_id': 'evt_02',
        'notification_event': 'trip_completed',
        'notification': {
          'title': 'Trip Completed!',
          'body': 'You have arrived.',
        },
        'payload': {'fare': '2500'},
      }, NotificationChannel.inAppRealtime);

      await pumpEventQueue();

      expect(captured.length, 2);
      expect(captured[0].event, NotificationEvent.tripStarted);
      expect(captured[0].channel, NotificationChannel.fcm);

      expect(captured[1].event, NotificationEvent.tripCompleted);
      expect(captured[1].channel, NotificationChannel.inAppRealtime);

      expect(capturedEvents, [NotificationEvent.tripStarted, NotificationEvent.tripCompleted]);
      expect(service.notifications.length, 2);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('Deduplicates duplicate event transmissions within app session', () async {
      final List<AppNotification> captured = [];
      final sub = service.notificationStream.listen(captured.add);

      // Send same event twice (e.g. delivered via FCM and concurrently via Realtime)
      final payload = {
        'message_id': 'unique_event_99',
        'data': {
          'event_id': 'unique_event_99',
          'event': 'driver_arrived',
          'title': 'Driver Has Arrived!',
          'body': 'Waiting outside',
        },
      };

      service.handleIncomingPayload(payload, NotificationChannel.fcm);
      service.handleIncomingPayload(payload, NotificationChannel.inAppRealtime);

      await pumpEventQueue();

      expect(captured.length, 1);
      expect(service.notifications.length, 1);

      await sub.cancel();
    });

    test('Marks notification as read and clears notification history', () {
      service.handleIncomingPayload({
        'message_id': 'unread_01',
        'data': {'event': 'payment_pending', 'title': 'Pay Driver', 'body': '₦2,000'},
      }, NotificationChannel.fcm);

      expect(service.notifications.first.isRead, false);

      service.markAsRead('unread_01');
      expect(service.notifications.first.isRead, true);

      service.clearAll();
      expect(service.notifications.isEmpty, true);
    });

    test('Device token lifecycle management', () async {
      await service.registerDeviceToken('device_token_abc_123');
      expect(service.activeDeviceToken, 'device_token_abc_123');
      expect(service.fcmHandler.currentToken, 'device_token_abc_123');

      await service.unregisterDeviceToken();
      expect(service.activeDeviceToken, isNull);
    });
  });

  group('InAppNotificationBanner Widget Tests', () {
    testWidgets('Renders banner with icon, title, body, and responds to taps', (tester) async {
      bool tapped = false;
      bool dismissed = false;

      final notif = AppNotification(
        id: 'banner_test_01',
        event: NotificationEvent.driverArriving,
        channel: NotificationChannel.inAppRealtime,
        title: 'Driver Has Arrived!',
        body: 'Share start PIN 4321 with your driver.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InAppNotificationBanner(
              notification: notif,
              onTap: () => tapped = true,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Driver Has Arrived!'), findsOneWidget);
      expect(find.text('Share start PIN 4321 with your driver.'), findsOneWidget);
      expect(find.byIcon(Icons.pin_drop_rounded), findsOneWidget);

      await tester.tap(find.text('Driver Has Arrived!'));
      expect(tapped, true);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, true);
    });
  });
}

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/logger/log.dart';
import '../../models/notification_model.dart';
import 'notification_service.dart';

class NotificationServiceImpl extends NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;
  String? _cachedToken;

  final _notificationController =
      StreamController<NotificationModel>.broadcast();

  @override
  Stream<NotificationModel> get onNotification =>
      _notificationController.stream;

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    _cachedToken = fcmToken;
    Log.info('FCM Token Cached: $_cachedToken');

    if (fcmToken != null) {
      Log.info('✅ FCM Token: $fcmToken');
    } else {
      Log.warning(
        '⚠️ FCM Token is null. Make sure Firebase is configured correctly.',
      );
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Log.info('Foreground message: ${message.notification?.title}');
      Log.info('Message data: ${message.data}');

      final notification = _parseNotification(message);
      if (notification != null) {
        _notificationController.add(notification);
      }
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Log.info('App opened from background: ${message.notification?.title}');
      Log.info('Message data: ${message.data}');

      final notification = _parseNotification(message);
      if (notification != null) {
        _notificationController.add(notification);
      }
    });

    // Handle messages when app is opened from terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      Log.info('App opened from terminated state via notification');
      Log.info('Message data: ${initialMessage.data}');

      final notification = _parseNotification(initialMessage);
      if (notification != null) {
        _notificationController.add(notification);
      }
    }
  }

  NotificationModel? _parseNotification(RemoteMessage message) {
    try {
      final payload = message.data.isNotEmpty
          ? NotificationPayloadModel.fromJson(message.data)
          : null;

      return NotificationModel(
        title: message.notification?.title,
        body: message.notification?.body,
        payload: payload,
      );
    } catch (e) {
      Log.error('Error parsing notification: $e');
      return null;
    }
  }

  @override
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  void dispose() {
    _notificationController.close();
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Log.info('''
╔═══════════════════════════════════════════════════════════════
║ 🔔 BACKGROUND MESSAGE RECEIVED
╠═══════════════════════════════════════════════════════════════
║ Message ID: ${message.messageId ?? 'N/A'}
║ Sent Time: ${message.sentTime ?? 'N/A'}
╠═══════════════════════════════════════════════════════════════
║ 📬 NOTIFICATION
║   Title: ${message.notification?.title ?? 'N/A'}
║   Body: ${message.notification?.body ?? 'N/A'}
╠═══════════════════════════════════════════════════════════════
║ 📦 DATA PAYLOAD
${message.data.isEmpty ? '║   ⚠️  No data payload' : message.data.entries.map((e) => '║   ${e.key}: ${e.value}').join('\n')}
╚═══════════════════════════════════════════════════════════════
''');
}

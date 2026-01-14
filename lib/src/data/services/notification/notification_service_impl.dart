import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/logger/log.dart';
import '../../../domain/entities/notification_payload_entity.dart';
import '../../models/notification_model.dart';
import 'notification_service.dart';

class NotificationServiceImpl extends NotificationService {
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  String? _cachedToken;

  NotificationPayloadEntity? _payload;
  @override
  NotificationPayloadEntity? get payload => _payload;

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
        _payload = notification.payload;
        _notificationController.add(notification);
      }
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Log.info('App opened from background: ${message.notification?.title}');
      Log.info('Message data: ${message.data}');

      final notification = _parseNotification(message);
      if (notification != null) {
        _payload = notification.payload;
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
        _payload = notification.payload;
        _notificationController.add(notification);
      }
    }

    // Handle FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _cachedToken = newToken;
      Log.info('FCM Token refreshed: $newToken');
      // TODO: Send updated token to backend
    });
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
    // Return cached token first (faster)
    if (_cachedToken != null) return _cachedToken;

    // Fallback to fresh token request
    final token = await FirebaseMessaging.instance.getToken();
    _cachedToken = token;
    return token;
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

# 🎨 Advanced Features & Customization

> **Journey Step 4:** Taking your notification system to the next level

---

## 📋 Table of Contents
1. [Custom Notification UI](#custom-notification-ui)
2. [Notification Badges](#notification-badges)
3. [Notification Actions](#notification-actions)
4. [Data-Only Messages](#data-only-messages)
5. [Topic Subscriptions](#topic-subscriptions)
6. [Token Management](#token-management)
7. [Analytics & Tracking](#analytics--tracking)

---

## 🎨 Custom Notification UI

### Foreground Notifications with Flutter Local Notifications

When app is in foreground, system doesn't show notification by default. Show custom UI:

#### Install Package

```yaml
dependencies:
  flutter_local_notifications: ^16.3.0
```

#### Initialize Local Notifications

```dart
// lib/src/data/services/notification/local_notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        _handleNotificationTap(details.payload);
      },
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  static Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''), // For long text
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      message.hashCode, // Unique ID
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(), // Pass data for tap handling
    );
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      // Parse payload and navigate
      // You can use your navigation service here
    }
  }
}
```

#### Update NotificationServiceImpl

```dart
@override
Future<void> initialize() async {
  // ... existing code ...

  // Initialize local notifications
  await LocalNotificationService.initialize();

  // Handle FOREGROUND messages with custom UI
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    Log.info('📱 Foreground: ${message.notification?.title}');

    // Show custom notification
    LocalNotificationService.showNotification(message);

    // Also add to stream for app logic
    final notification = _parseNotification(message);
    if (notification != null) {
      _payload = notification.payload;
      _notificationController.add(notification);
    }
  });

  // ... rest of code ...
}
```

---

### Custom In-App Banner

Alternative to system notifications - show custom UI:

```dart
// lib/src/presentation/core/widgets/notification_banner.dart

import 'package:flutter/material.dart';

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              entry.remove();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => entry.remove(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
```

**Usage:**

```dart
FirebaseMessaging.onMessage.listen((message) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    NotificationBanner.show(
      context,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      onTap: () {
        // Navigate to relevant screen
        context.go('/notification-details');
      },
    );
  }
});
```

---

## 🔴 Notification Badges

### iOS Badge Management

```dart
// lib/src/data/services/notification/badge_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';

class BadgeService {
  static Future<void> setBadgeCount(int count) async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      // Use flutter_app_badger or similar package
      // FlutterAppBadger.updateBadgeCount(count);
    }
  }

  static Future<void> clearBadge() async {
    await setBadgeCount(0);
  }

  static Future<void> incrementBadge() async {
    // Track locally or fetch from server
    // final current = await getCurrentBadgeCount();
    // await setBadgeCount(current + 1);
  }
}
```

**Update on notification received:**

```dart
FirebaseMessaging.onMessage.listen((message) {
  BadgeService.incrementBadge();
  // ... handle notification
});

// Clear when user opens app
void clearBadgesOnAppForeground() {
  BadgeService.clearBadge();
}
```

---

## 🎯 Notification Actions

Add action buttons to notifications:

### Android Configuration

```dart
const androidDetails = AndroidNotificationDetails(
  'high_importance_channel',
  'High Importance Notifications',
  actions: [
    AndroidNotificationAction(
      'view',
      'View',
      showsUserInterface: true,
    ),
    AndroidNotificationAction(
      'dismiss',
      'Dismiss',
      cancelNotification: true,
    ),
  ],
);
```

### iOS Configuration

```dart
const iosDetails = DarwinNotificationDetails(
  categoryIdentifier: 'notification_actions',
);

// Register categories
await _notifications
    .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
    ?.initialize(
      DarwinInitializationSettings(
        notificationCategories: [
          DarwinNotificationCategory(
            'notification_actions',
            actions: [
              DarwinNotificationAction.plain('view', 'View'),
              DarwinNotificationAction.plain('dismiss', 'Dismiss'),
            ],
          ),
        ],
      ),
    );
```

### Handle Action Taps

```dart
await _notifications.initialize(
  settings,
  onDidReceiveNotificationResponse: (details) {
    switch (details.actionId) {
      case 'view':
        // Navigate to details
        break;
      case 'dismiss':
        // Dismiss action
        break;
      default:
        // Default tap action
    }
  },
);
```

---

## 📡 Data-Only Messages

Send silent notifications for background data sync:

### Backend Sends Data-Only Message

```json
{
  "message": {
    "token": "user_fcm_token",
    "data": {
      "type": "sync",
      "syncType": "products",
      "timestamp": "2024-01-14T12:00:00Z"
    }
  }
}
```

**No `notification` field = silent delivery**

### Handle Data-Only Messages

```dart
FirebaseMessaging.onMessage.listen((message) {
  if (message.notification == null) {
    // Data-only message - handle silently
    final syncType = message.data['syncType'];
    
    switch (syncType) {
      case 'products':
        syncProducts();
        break;
      case 'orders':
        syncOrders();
        break;
      default:
        Log.info('Unknown sync type: $syncType');
    }
  } else {
    // Regular notification - show UI
    showNotification(message);
  }
});
```

---

## 📢 Topic Subscriptions

Subscribe users to notification topics:

### Subscribe to Topics

```dart
// lib/src/domain/use_cases/topic_subscription_use_case.dart

class SubscribeToTopicUseCase {
  Future<void> call(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    Log.info('✅ Subscribed to topic: $topic');
  }
}

class UnsubscribeFromTopicUseCase {
  Future<void> call(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    Log.info('❌ Unsubscribed from topic: $topic');
  }
}
```

### Usage in Settings

```dart
class NotificationSettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        SwitchListTile(
          title: Text('New Products'),
          value: ref.watch(topicSubscriptionProvider('new_products')),
          onChanged: (value) {
            if (value) {
              ref.read(subscribeToTopicUseCaseProvider).call('new_products');
            } else {
              ref.read(unsubscribeFromTopicUseCaseProvider).call('new_products');
            }
          },
        ),
        SwitchListTile(
          title: Text('Sales & Offers'),
          value: ref.watch(topicSubscriptionProvider('sales')),
          onChanged: (value) {
            if (value) {
              ref.read(subscribeToTopicUseCaseProvider).call('sales');
            } else {
              ref.read(unsubscribeFromTopicUseCaseProvider).call('sales');
            }
          },
        ),
      ],
    );
  }
}
```

### Send to Topic (Backend)

```json
{
  "message": {
    "topic": "new_products",
    "notification": {
      "title": "New Arrivals!",
      "body": "Check out our latest collection"
    },
    "data": {
      "type": "collection",
      "collectionId": "new_arrivals"
    }
  }
}
```

---

## 🔑 Token Management

### Send Token to Backend

```dart
// lib/src/domain/use_cases/sync_fcm_token_use_case.dart

class SyncFcmTokenUseCase {
  SyncFcmTokenUseCase(this._apiClient, this._notificationRepository);

  final ApiClient _apiClient;
  final NotificationRepository _notificationRepository;

  Future<void> call() async {
    final token = await _notificationRepository.getFcmToken();
    
    if (token != null) {
      try {
        await _apiClient.post(
          '/api/v1/fcm/token',
          data: {
            'token': token,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'deviceId': await getDeviceId(),
          },
        );
        Log.info('✅ FCM token synced with backend');
      } catch (e) {
        Log.error('❌ Failed to sync FCM token: $e');
      }
    }
  }
}
```

### Handle Token Refresh

```dart
// Already in NotificationServiceImpl
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  _cachedToken = newToken;
  Log.info('🔄 FCM Token refreshed: $newToken');
  
  // Sync with backend
  ref.read(syncFcmTokenUseCaseProvider).call();
});
```

### Delete Token on Logout

```dart
class LogoutUseCase {
  Future<void> call() async {
    // Delete FCM token
    await FirebaseMessaging.instance.deleteToken();
    Log.info('🗑️ FCM token deleted');
    
    // Clear user session
    await clearUserSession();
    
    // Navigate to login
    navigateToLogin();
  }
}
```

---

## 📊 Analytics & Tracking

### Track Notification Events

```dart
// lib/src/core/analytics/notification_analytics.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class NotificationAnalytics {
  static final _analytics = FirebaseAnalytics.instance;

  static Future<void> logNotificationReceived({
    required String notificationType,
    required String? title,
  }) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {
        'notification_type': notificationType,
        'title': title ?? 'N/A',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logNotificationOpened({
    required String notificationType,
    required String? title,
    required String source, // 'foreground', 'background', 'terminated'
  }) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'notification_type': notificationType,
        'title': title ?? 'N/A',
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<void> logNotificationDismissed({
    required String notificationType,
  }) async {
    await _analytics.logEvent(
      name: 'notification_dismissed',
      parameters: {
        'notification_type': notificationType,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

### Integrate with Notification Service

```dart
FirebaseMessaging.onMessage.listen((message) {
  // Track received
  NotificationAnalytics.logNotificationReceived(
    notificationType: message.data['type'] ?? 'unknown',
    title: message.notification?.title,
  );

  // ... handle notification
});

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Track opened from background
  NotificationAnalytics.logNotificationOpened(
    notificationType: message.data['type'] ?? 'unknown',
    title: message.notification?.title,
    source: 'background',
  );

  // ... handle navigation
});
```

---

## 🔒 Security Best Practices

### 1. Validate Notification Data

```dart
NotificationModel? _parseNotification(RemoteMessage message) {
  try {
    // Validate data structure
    if (!_isValidPayload(message.data)) {
      Log.warning('⚠️ Invalid notification payload');
      return null;
    }

    final payload = message.data.isNotEmpty
        ? NotificationPayloadModel.fromJson(message.data)
        : null;

    return NotificationModel(
      title: message.notification?.title,
      body: message.notification?.body,
      payload: payload,
    );
  } catch (e) {
    Log.error('❌ Error parsing notification: $e');
    return null;
  }
}

bool _isValidPayload(Map<String, dynamic> data) {
  // Check required fields
  if (data.isEmpty) return true; // Data-only is optional

  final type = data['type'];
  if (type == null) return false;

  // Validate based on type
  switch (type) {
    case 'collection':
      return data.containsKey('collectionId');
    case 'cart':
      return true;
    case 'home':
      return true;
    default:
      return false;
  }
}
```

### 2. Sanitize Deep Link URLs

```dart
void navigateFromNotification(NotificationPayloadEntity payload) {
  // Validate URL
  if (payload.checkOutUrl.isNotEmpty) {
    final uri = Uri.tryParse(payload.checkOutUrl);
    
    // Only allow your domain
    if (uri != null && uri.host == 'yourdomain.com') {
      launchUrl(uri);
    } else {
      Log.warning('⚠️ Invalid URL in notification: ${payload.checkOutUrl}');
    }
  }
}
```

### 3. Rate Limiting

```dart
class NotificationRateLimiter {
  static final Map<String, DateTime> _lastReceived = {};
  static const _minInterval = Duration(seconds: 5);

  static bool shouldProcess(String notificationType) {
    final now = DateTime.now();
    final last = _lastReceived[notificationType];

    if (last != null && now.difference(last) < _minInterval) {
      Log.warning('⚠️ Rate limit: Too many $notificationType notifications');
      return false;
    }

    _lastReceived[notificationType] = now;
    return true;
  }
}

// Usage
FirebaseMessaging.onMessage.listen((message) {
  final type = message.data['type'] ?? 'unknown';
  
  if (!NotificationRateLimiter.shouldProcess(type)) {
    return; // Skip this notification
  }

  // Process notification
  handleNotification(message);
});
```

---

## 🎨 Custom Notification Sounds

### Android

1. Add sound file to `android/app/src/main/res/raw/notification_sound.mp3`

2. Reference in notification:

```dart
const androidDetails = AndroidNotificationDetails(
  'high_importance_channel',
  'High Importance Notifications',
  sound: RawResourceAndroidNotificationSound('notification_sound'),
  playSound: true,
);
```

### iOS

1. Add sound file to Xcode project (must be `.aiff`, `.caf`, or `.wav`)
2. Reference in notification:

```dart
const iosDetails = DarwinNotificationDetails(
  sound: 'notification_sound.aiff',
  presentSound: true,
);
```

---

## 📚 Next Steps

- ✅ Advanced features covered!
- 📍 Next: [Testing & Debugging](./05_testing_guide.md)
- 📍 Then: [Production Deployment](./06_deployment_guide.md)

---

## 🔗 References

- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [FCM Topic Messaging](https://firebase.google.com/docs/cloud-messaging/android/topic-messaging)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)

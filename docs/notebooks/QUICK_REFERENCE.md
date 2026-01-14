# 📋 Quick Reference Guide

> **Cheat sheet** for common Firebase Push Notification tasks

---

## 🚀 Quick Setup Commands

### Firebase Initialization
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure

# Add dependencies
flutter pub add firebase_core firebase_messaging
```

### Get FCM Token
```dart
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

---

## 🔔 Notification Handlers

### Foreground
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('Foreground: ${message.notification?.title}');
  // Show custom UI
});
```

### Background → Foreground
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('Opened from background');
  // Navigate to screen
});
```

### Terminated → Foreground
```dart
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  print('Opened from terminated state');
  // Handle navigation
}
```

### Background (Top-level function)
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

// Register in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}
```

---

## 🔐 Permission Handling

### Request Permission
```dart
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  print('✅ Permission granted');
}
```

### Check Permission
```dart
NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();

switch (settings.authorizationStatus) {
  case AuthorizationStatus.authorized:
    print('✅ Authorized');
    break;
  case AuthorizationStatus.denied:
    print('❌ Denied');
    break;
  case AuthorizationStatus.notDetermined:
    print('⏸️ Not asked yet');
    break;
  case AuthorizationStatus.provisional:
    print('🔕 Provisional');
    break;
}
```

---

## 📱 Platform-Specific Code

### iOS Configuration (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
  <key>remote-notification</key>
</array>
```

### Android Configuration (AndroidManifest.xml)
```xml
<!-- Android 13+ permission -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Default notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

---

## 🎯 Common Payload Structures

### Notification + Data
```json
{
  "message": {
    "token": "user_fcm_token",
    "notification": {
      "title": "New Message",
      "body": "You have a new message"
    },
    "data": {
      "type": "message",
      "messageId": "123",
      "senderId": "456"
    }
  }
}
```

### Data Only (Silent)
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

### Topic Message
```json
{
  "message": {
    "topic": "news",
    "notification": {
      "title": "Breaking News",
      "body": "Important update"
    }
  }
}
```

---

## 🔄 Topic Subscriptions

### Subscribe
```dart
await FirebaseMessaging.instance.subscribeToTopic('news');
```

### Unsubscribe
```dart
await FirebaseMessaging.instance.unsubscribeFromTopic('news');
```

---

## 📊 Debugging Commands

### Get Token
```dart
String? token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

### Check Permission Status
```dart
NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Authorization: ${settings.authorizationStatus}');
print('Alert: ${settings.alert}');
print('Badge: ${settings.badge}');
print('Sound: ${settings.sound}');
```

### Delete Token
```dart
await FirebaseMessaging.instance.deleteToken();
```

### Android ADB Logs
```bash
adb logcat | grep -E "FCM|Firebase|Notification"
```

---

## 🧪 Testing Snippets

### Send Test from Firebase Console
1. Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Paste FCM token
4. Add notification title/body
5. Add custom data (optional)
6. Click "Test"

### Manual Test Notification
```dart
void testNotification() async {
  final token = await FirebaseMessaging.instance.getToken();
  print('Send test to: $token');
  
  // Listen for notifications
  FirebaseMessaging.onMessage.listen((message) {
    print('✅ Received: ${message.notification?.title}');
  });
}
```

---

## 🎨 Custom UI Snippets

### Show Local Notification
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails();

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    details,
  );
}
```

### Show In-App Banner
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(message.notification?.body ?? 'New notification'),
    action: SnackBarAction(
      label: 'View',
      onPressed: () {
        // Navigate
      },
    ),
  ),
);
```

---

## 🔍 Common Error Solutions

### Token is Null
```dart
// ✅ Ensure Firebase is initialized
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// ✅ Check permission
final settings = await FirebaseMessaging.instance.getNotificationSettings();
if (settings.authorizationStatus == AuthorizationStatus.denied) {
  print('Permission denied');
}

// ✅ Verify config files
// Android: android/app/google-services.json
// iOS: ios/Runner/GoogleService-Info.plist
```

### Notifications Not Showing
```dart
// iOS: Test on real device (not simulator)
// Android 13+: Check POST_NOTIFICATIONS permission
// Both: Verify notification permission granted
```

### Background Handler Not Working
```dart
// ✅ Must be top-level function
@pragma('vm:entry-point')
Future<void> _handler(RemoteMessage message) async {
  // Your code
}

// ✅ Register before getting token
FirebaseMessaging.onBackgroundMessage(_handler);
```

---

## 📦 Useful Packages

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  go_router: ^13.0.0
  riverpod: ^2.4.9
  
dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

---

## 🎯 Navigation Examples

### Simple Navigation
```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final route = message.data['route'];
  Navigator.pushNamed(context, route);
});
```

### GoRouter Navigation
```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final route = message.data['route'];
  context.go(route);
});
```

### With Parameters
```dart
final type = message.data['type'];
final id = message.data['id'];

switch (type) {
  case 'product':
    context.go('/products/$id');
    break;
  case 'order':
    context.go('/orders/$id');
    break;
}
```

---

## 🔒 Security Checklist

- [ ] Validate notification payload
- [ ] Sanitize deep link URLs
- [ ] Never store sensitive data in notifications
- [ ] Implement rate limiting
- [ ] Use HTTPS for backend communication
- [ ] Verify data structure before parsing
- [ ] Handle malformed data gracefully

---

## 📊 Performance Tips

### Token Caching
```dart
String? _cachedToken;

Future<String?> getToken() async {
  if (_cachedToken != null) return _cachedToken;
  _cachedToken = await FirebaseMessaging.instance.getToken();
  return _cachedToken;
}
```

### Stream Optimization
```dart
// Use broadcast stream for multiple listeners
final _controller = StreamController<NotificationModel>.broadcast();
```

### Efficient Parsing
```dart
NotificationModel? parseNotification(RemoteMessage message) {
  try {
    // Fast path: No data
    if (message.data.isEmpty) {
      return NotificationModel(
        title: message.notification?.title,
        body: message.notification?.body,
      );
    }
    
    // Parse data
    return NotificationModel.fromRemoteMessage(message);
  } catch (e) {
    Log.error('Parse error: $e');
    return null;
  }
}
```

---

## 🎓 Learning Resources

### Official Docs
- [FlutterFire](https://firebase.flutter.dev/)
- [FCM Docs](https://firebase.google.com/docs/cloud-messaging)
- [Apple APNs](https://developer.apple.com/notifications/)

### Video Tutorials
- Search: "Flutter Firebase Push Notifications"
- YouTube Flutter channel

### Community
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter+firebase-cloud-messaging)
- [Flutter Discord](https://discord.gg/flutter)

---

## 📋 Testing Checklist

- [ ] Foreground notification works
- [ ] Background notification works
- [ ] Terminated state notification works
- [ ] Navigation from notification works
- [ ] Permission dialog shows (first time)
- [ ] FCM token generated
- [ ] Token synced with backend
- [ ] Data payload parsed correctly
- [ ] Error handling works
- [ ] Tested on real devices (iOS & Android)

---

## 🚀 Production Checklist

- [ ] Firebase project in production mode
- [ ] APNs production certificate uploaded (iOS)
- [ ] Notification icons configured
- [ ] Analytics integrated
- [ ] Error tracking enabled
- [ ] Token refresh handled
- [ ] User preferences respected
- [ ] GDPR compliance (if applicable)
- [ ] Rate limiting implemented
- [ ] Monitoring and alerts set up

---

**Quick tip:** Bookmark this page for fast reference! 🔖

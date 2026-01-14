# Firebase Push Notifications Implementation Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Platform-Specific Behavior](#platform-specific-behavior)
4. [Permission Handling](#permission-handling)
5. [Notification States](#notification-states)
6. [Implementation Details](#implementation-details)
7. [Testing & Debugging](#testing--debugging)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Overview

This application implements Firebase Cloud Messaging (FCM) for push notifications using a clean architecture approach. The implementation supports:

- ✅ Foreground notifications (app is open and active)
- ✅ Background notifications (app is in background)
- ✅ Terminated state notifications (app is completely closed)
- ✅ Deep linking and navigation from notifications
- ✅ Custom notification payloads
- ✅ Cross-platform support (iOS & Android)

### Key Dependencies
```yaml
firebase_core: ^4.3.0
firebase_messaging: ^16.1.0
```

---

## Architecture

### Layer Structure

```
┌─────────────────────────────────────────────────────┐
│              Presentation Layer                      │
│  ┌──────────────────────────────────────────────┐   │
│  │ NotificationNavigationService                 │   │
│  │ (Handles navigation based on payloads)       │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                Domain Layer                          │
│  ┌──────────────────────────────────────────────┐   │
│  │ Use Cases:                                    │   │
│  │ • InitializeNotificationUseCase              │   │
│  │ • GetNotificationStreamUseCase               │   │
│  ├──────────────────────────────────────────────┤   │
│  │ Entities:                                     │   │
│  │ • NotificationEntity                         │   │
│  │ • NotificationPayloadEntity                  │   │
│  │ • NotificationType (enum)                    │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│                 Data Layer                           │
│  ┌──────────────────────────────────────────────┐   │
│  │ NotificationRepositoryImpl                    │   │
│  └──────────────────────────────────────────────┘   │
│                        ↓                             │
│  ┌──────────────────────────────────────────────┐   │
│  │ NotificationServiceImpl                       │   │
│  │ (Firebase Messaging Integration)             │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Component Responsibilities

#### 1. **NotificationServiceImpl** (Data Layer)
- Initializes Firebase Messaging
- Requests notification permissions
- Manages FCM token
- Listens to foreground, background, and terminated state messages
- Parses remote messages into domain models
- Exposes notification stream

#### 2. **NotificationRepositoryImpl** (Data Layer)
- Implements domain repository interface
- Delegates to NotificationService
- Bridges data and domain layers

#### 3. **Use Cases** (Domain Layer)
- `InitializeNotificationUseCase`: Initializes notification system
- `GetNotificationStreamUseCase`: Provides stream of incoming notifications

#### 4. **NotificationNavigationService** (Presentation Layer)
- Handles navigation based on notification type
- Maps payload data to routes
- Respects authentication guards

---

## Platform-Specific Behavior

### iOS (Apple Push Notification Service - APNs)

#### Configuration Requirements
1. **APNs Certificate/Key**: Must be uploaded to Firebase Console
2. **Capabilities**: Background Modes enabled in Xcode
   - Remote notifications
   - Background fetch (optional)
3. **Info.plist**: No special permissions required for basic notifications

#### Permission Behavior

##### First Time (Never Asked)
```dart
await _firebaseMessaging.requestPermission();
```
- **Shows system dialog** with options:
  - Allow
  - Don't Allow
- User choice is permanent until app reinstall or settings change

##### When Permission is Granted
- **FCM Token**: Generated immediately
- **Notifications work in**:
  - ✅ Foreground (handled by `onMessage`)
  - ✅ Background (handled by `onBackgroundMessage`)
  - ✅ Terminated (handled by `getInitialMessage`)
- **Alert styles**: Banner, Alert, Badge, Sound (configurable in Settings)
- **User can modify**: Settings → Notifications → Your App

##### When Permission is Denied
- **FCM Token**: `null` (won't be generated)
- **Notifications**: Will NOT be delivered at all
- **User must**: Go to Settings → Notifications → Your App → Allow Notifications
- **App cannot**: Programmatically re-request (system limitation)

##### Provisional Authorization (iOS 12+)
```dart
await _firebaseMessaging.requestPermission(
  provisional: true, // Silent notifications
);
```
- Delivers notifications silently to Notification Center
- No interruption to user
- User can enable full notifications from Notification Center

#### iOS Notification States

| App State    | Delivery | Handling Method          | Banner Shown | Badge | Sound |
|-------------|----------|--------------------------|--------------|-------|-------|
| Foreground  | ✅       | `onMessage`              | No*          | Yes   | No*   |
| Background  | ✅       | `onBackgroundMessage`    | Yes          | Yes   | Yes   |
| Terminated  | ✅       | `getInitialMessage`      | Yes          | Yes   | Yes   |

*Can be customized with local notification plugins

---

### Android (Firebase Cloud Messaging)

#### Configuration Requirements
1. **google-services.json**: Must be in `android/app/`
2. **Minimum SDK**: 21+ (Android 5.0 Lollipop)
3. **AndroidManifest.xml**: Default notification channel configured

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
```

#### Permission Behavior

##### Android 12 and Below (API < 33)
- **No runtime permission required** for notifications
- Notifications are **enabled by default**
- `requestPermission()` returns granted automatically
- FCM token generated immediately

##### Android 13+ (API 33+)
```dart
await _firebaseMessaging.requestPermission();
```
- **Shows system dialog**:
  - Allow
  - Don't allow
- Similar to iOS behavior
- **POST_NOTIFICATIONS** permission required

##### When Permission is Granted
- **FCM Token**: Generated immediately
- **Notifications work in**:
  - ✅ Foreground (handled by `onMessage`)
  - ✅ Background (handled by `onBackgroundMessage`)
  - ✅ Terminated (handled by `getInitialMessage`)
- **User can disable**: Settings → Apps → Your App → Notifications

##### When Permission is Denied (Android 13+)
- **FCM Token**: Still generated (but notifications won't show)
- **Data messages**: Still delivered (silent)
- **Notification messages**: Won't show in system tray
- **User must**: Enable in Settings → Apps → Notifications

##### Notification Channels (Android 8.0+)
- Required for Android O and above
- Defined in native code or at runtime
- Users can customize per channel:
  - Importance level
  - Sound
  - Vibration
  - Badge

#### Android Notification States

| App State    | Delivery | Handling Method          | System Tray | Badge | Sound | Data |
|-------------|----------|--------------------------|-------------|-------|-------|------|
| Foreground  | ✅       | `onMessage`              | No*         | Yes*  | No*   | Yes  |
| Background  | ✅       | `onBackgroundMessage`    | Yes         | Yes   | Yes   | Yes  |
| Terminated  | ✅       | `getInitialMessage`      | Yes         | Yes   | Yes   | Yes  |

*Can be customized with local notification plugins (e.g., `flutter_local_notifications`)

---

## Permission Handling

### Current Implementation

```dart
// Location: lib/src/data/services/notification/notification_service_impl.dart

@override
Future<void> initialize() async {
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request permissions
  await _firebaseMessaging.requestPermission();
  
  // Get FCM token
  final fcmToken = await _firebaseMessaging.getToken();
  _cachedToken = fcmToken;
  
  if (fcmToken != null) {
    Log.info('✅ FCM Token: $fcmToken');
  } else {
    Log.warning('⚠️ FCM Token is null. Check Firebase configuration.');
  }
  
  // Set up listeners...
}
```

### What Happens on Permission Request?

#### iOS Behavior Flow
```
┌──────────────────────────────────────┐
│ requestPermission() called            │
└───────────┬──────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│ System Dialog Appears                 │
│ ┌──────────────────────────────────┐ │
│ │ "App" Would Like to Send You     │ │
│ │ Notifications                     │ │
│ │                                   │ │
│ │ [Don't Allow]  [Allow]           │ │
│ └──────────────────────────────────┘ │
└───────────┬──────────────────────────┘
            ↓
    ┌───────┴────────┐
    │                │
    ↓                ↓
[Allow]          [Don't Allow]
    │                │
    ↓                ↓
FCM Token         FCM Token = null
Generated         No notifications
```

#### Android Behavior Flow

**Android 12 and below:**
```
┌──────────────────────────────────────┐
│ requestPermission() called            │
└───────────┬──────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│ Automatically Granted                 │
│ (No dialog shown)                     │
└───────────┬──────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│ FCM Token Generated                   │
│ Notifications enabled by default      │
└──────────────────────────────────────┘
```

**Android 13+:**
```
┌──────────────────────────────────────┐
│ requestPermission() called            │
└───────────┬──────────────────────────┘
            ↓
┌──────────────────────────────────────┐
│ System Dialog Appears                 │
│ ┌──────────────────────────────────┐ │
│ │ Allow [App] to send you          │ │
│ │ notifications?                    │ │
│ │                                   │ │
│ │ [Don't allow]  [Allow]           │ │
│ └──────────────────────────────────┘ │
└───────────┬──────────────────────────┘
            ↓
    ┌───────┴────────┐
    │                │
    ↓                ↓
[Allow]          [Don't Allow]
    │                │
    ↓                ↓
FCM Token         FCM Token Generated*
Notifications     No UI notifications
Enabled           (Data messages work)

* Token is generated but notifications won't show
```

### Advanced Permission Handling (Recommended)

For better UX, implement permission status checking:

```dart
Future<void> requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;
  
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    Log.info('✅ User granted permission');
    // Proceed with normal flow
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    Log.info('📌 User granted provisional permission');
    // Silent notifications enabled
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    Log.warning('❌ User denied permission');
    // Show guidance to enable in settings
    _showEnableNotificationsDialog();
  } else {
    Log.info('⏳ Permission not determined yet');
  }
}
```

### Permission Status Types

| Status | iOS | Android < 13 | Android 13+ | Description |
|--------|-----|--------------|-------------|-------------|
| `authorized` | ✅ | ✅ | ✅ | Full permission granted |
| `denied` | ✅ | ❌ | ✅ | User explicitly denied |
| `notDetermined` | ✅ | ❌ | ❌ | Not asked yet (iOS only) |
| `provisional` | ✅ | ❌ | ❌ | Silent notifications (iOS 12+) |

---

## Notification States

### 1. Foreground Notifications

**Definition**: App is open and user is actively using it.

**Behavior**:
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  Log.info('Foreground message: ${message.notification?.title}');
  
  final notification = _parseNotification(message);
  if (notification != null) {
    _notificationController.add(notification);
  }
});
```

**What Happens**:
- ✅ Notification data is received
- ✅ Custom handler is triggered
- ❌ System UI notification is NOT shown automatically
- ✅ You can display custom in-app UI
- ✅ Data payload is accessible

**When to Use**:
- Show custom in-app banner/toast
- Update UI immediately
- Handle real-time data updates

**Example Use Case**:
```dart
// Show a custom SnackBar when notification arrives
onMessage.listen((message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message.notification?.body ?? 'New notification'),
      action: SnackBarAction(
        label: 'View',
        onPressed: () => navigateToDetails(message.data),
      ),
    ),
  );
});
```

---

### 2. Background Notifications

**Definition**: App is running but not in the foreground (minimized, screen locked, etc.).

**Behavior**:
```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Log.info('Background message received');
  Log.info('Title: ${message.notification?.title}');
  Log.info('Data: ${message.data}');
}
```

**What Happens**:
- ✅ System notification is shown automatically
- ✅ Background handler is executed
- ✅ Sound/vibration plays (if enabled)
- ✅ Badge count updates
- ✅ Data payload is accessible
- ⚠️ Limited execution time (~30 seconds)

**Important Notes**:
- Handler must be a **top-level function** (not inside a class)
- Must have `@pragma('vm:entry-point')` annotation
- Cannot access UI or BuildContext
- Should complete quickly

**When to Use**:
- Update local database
- Sync data
- Log analytics events
- Process data payloads

---

### 3. Terminated State Notifications

**Definition**: App is completely closed (not in memory).

**Behavior**:
```dart
// Check if app was opened from a notification
final initialMessage = await _firebaseMessaging.getInitialMessage();
if (initialMessage != null) {
  Log.info('App opened from terminated state via notification');
  
  final notification = _parseNotification(initialMessage);
  if (notification != null) {
    _notificationController.add(notification);
  }
}
```

**What Happens**:
- ✅ System notification is shown
- ✅ User taps notification to open app
- ✅ App launches
- ✅ `getInitialMessage()` returns the notification
- ✅ Can navigate to specific screen

**When to Use**:
- Deep linking on app launch
- Navigate to specific content
- Pre-load data before showing UI

**Example**:
```dart
if (initialMessage != null) {
  final type = initialMessage.data['type'];
  if (type == 'collection') {
    // Navigate to collection screen after app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/collection/${initialMessage.data['id']}');
    });
  }
}
```

---

### 4. Notification Opened from Background

**Definition**: App is in background, user taps notification.

**Behavior**:
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  Log.info('App opened from background: ${message.notification?.title}');
  
  final notification = _parseNotification(message);
  if (notification != null) {
    _notificationController.add(notification);
  }
});
```

**What Happens**:
- ✅ App comes to foreground
- ✅ Listener is triggered
- ✅ Can navigate to specific screen
- ✅ Full app context available

---

## Implementation Details

### Initialization Flow

```
App Start
    ↓
┌─────────────────────────────────────────┐
│ main() - WidgetsFlutterBinding          │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ appStartupProvider                       │
│ 1. Firebase.initializeApp()             │
│ 2. SharedPreferences initialization     │
│ 3. Localization setup                   │
│ 4. Notification initialization          │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ InitializeNotificationUseCase           │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ NotificationServiceImpl.initialize()    │
│ • Set background handler                │
│ • Request permission                    │
│ • Get FCM token                         │
│ • Set up message listeners              │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ App Ready - Notifications Active        │
└─────────────────────────────────────────┘
```

### Notification Data Structure

#### Notification Payload
```dart
class NotificationPayloadEntity {
  final NotificationType type;        // collection, cart, home
  final String collectionId;           // ID for deep linking
  final String collectionTitle;        // Display title
  final String checkOutUrl;            // Optional URL
}

enum NotificationType {
  collection,  // Public route
  cart,        // Protected route
  home,        // Protected route
}
```

#### Complete Notification Entity
```dart
class NotificationEntity {
  final String? title;                 // From FCM notification
  final String? body;                  // From FCM notification
  final NotificationPayloadEntity? payload;  // From FCM data
}
```

### FCM Message Format

#### Send this JSON from Firebase Console or Server:
```json
{
  "notification": {
    "title": "New Collection Available!",
    "body": "Check out our latest summer collection"
  },
  "data": {
    "type": "collection",
    "payload": "summer_2024"
  },
  "token": "USER_FCM_TOKEN"
}
```

#### Parsing Logic:
```dart
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
```

---

## Navigation Handling

### NotificationNavigationService

Handles routing based on notification payload:

```dart
void handleNotificationNavigation(
  GoRouter router,
  NotificationPayloadEntity payload,
) {
  String targetRoute;

  switch (payload.type) {
    case NotificationType.collection:
      targetRoute = Routes.collection;  // PUBLIC
      break;
    case NotificationType.cart:
      targetRoute = Routes.cart;        // PROTECTED
      break;
    case NotificationType.home:
      targetRoute = Routes.home;        // PROTECTED
      break;
  }

  router.go(targetRoute);
}
```

### Route Protection

- **Public Routes** (e.g., collection): Accessible without login
- **Protected Routes** (e.g., cart, home): Require authentication
- **Router Guard**: Automatically redirects to login if not authenticated

### Usage Example

```dart
// Listen to notification stream
ref.listen(notificationStreamProvider, (previous, next) {
  if (next case AsyncData(:final value)) {
    if (value.payload != null) {
      final navService = ref.read(notificationNavigationServiceProvider);
      final router = ref.read(goRouterProvider);
      
      navService.handleNotificationNavigation(router, value.payload!);
    }
  }
});
```

---

## Testing & Debugging

### 1. Get FCM Token

```dart
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

**Copy this token to test notifications.**

### 2. Send Test Notification from Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and body
4. Click "Send test message"
5. Paste your FCM token
6. Click "Test"

### 3. Send Notification with Data Payload

Use Firebase Console or REST API:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: Bearer YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test"
    },
    "data": {
      "type": "collection",
      "payload": "test_123"
    }
  }'
```

### 4. Debug Logs

Check logs for notification events:

```
✅ FCM Token: eyJ...  (Token generated successfully)
Foreground message: Test Notification  (Received in foreground)
Background message received  (Received in background)
App opened from terminated state  (Opened from notification)
```

### 5. Test Different States

| State | How to Test |
|-------|-------------|
| Foreground | App is open, send notification |
| Background | Minimize app, send notification |
| Terminated | Close app completely, send notification, tap it |
| Permission Denied | Deny permission, try to receive notifications |

---

## Best Practices

### 1. **Always Handle Token Refresh**

FCM tokens can change. Implement token refresh listener:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  Log.info('FCM Token refreshed: $newToken');
  // Send to your backend
  updateTokenOnServer(newToken);
});
```

### 2. **Gracefully Handle Permission Denial**

```dart
if (fcmToken == null) {
  // Show user-friendly message
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Enable Notifications'),
      content: Text(
        'To receive updates, please enable notifications in Settings.'
      ),
      actions: [
        TextButton(
          onPressed: () => openAppSettings(),
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

### 3. **Use Notification Channels (Android)**

```dart
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
);
```

### 4. **Show Foreground Notifications with Local Notifications**

```dart
// Install: flutter_local_notifications

FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  RemoteNotification? notification = message.notification;
  
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
        ),
      ),
    );
  }
});
```

### 5. **Secure Token Storage**

```dart
// Store token securely for backend sync
await secureStorage.write(key: 'fcm_token', value: token);
```

### 6. **Handle Notification Data Validation**

```dart
NotificationModel? _parseNotification(RemoteMessage message) {
  try {
    // Validate required fields
    if (message.data.isEmpty) {
      Log.warning('Notification has no data payload');
      return null;
    }
    
    // Parse with error handling
    final payload = NotificationPayloadModel.fromJson(message.data);
    
    return NotificationModel(
      title: message.notification?.title,
      body: message.notification?.body,
      payload: payload,
    );
  } catch (e, stackTrace) {
    Log.error('Error parsing notification', error: e, stackTrace: stackTrace);
    return null;
  }
}
```

---

## Troubleshooting

### Issue: FCM Token is null

**Possible Causes**:
1. Firebase not initialized properly
2. `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) missing
3. Permission denied (iOS)
4. Network connectivity issues
5. Firebase project not configured correctly

**Solutions**:
```bash
# Re-run FlutterFire CLI
flutterfire configure

# Check Firebase initialization
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

# Check permission status
final settings = await messaging.getNotificationSettings();
print(settings.authorizationStatus);
```

---

### Issue: Notifications not received in foreground (Android)

**Cause**: Android shows notifications in system tray by default, not in-app.

**Solution**: Use `flutter_local_notifications` to display foreground notifications.

---

### Issue: Background handler not working

**Possible Causes**:
1. Handler not top-level function
2. Missing `@pragma('vm:entry-point')`
3. Handler registered after messaging initialization

**Solution**:
```dart
// Must be top-level, outside any class
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Log.info('Background message: ${message.messageId}');
}

// Register BEFORE any other FCM operations
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register background handler first
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Then initialize app
  runApp(MyApp());
}
```

---

### Issue: Deep linking not working from notifications

**Cause**: Navigation called before app is ready.

**Solution**:
```dart
final initialMessage = await messaging.getInitialMessage();
if (initialMessage != null) {
  // Wait for app to be fully initialized
  WidgetsBinding.instance.addPostFrameCallback((_) {
    handleNotificationNavigation(initialMessage);
  });
}
```

---

### Issue: iOS notifications not showing

**Checklist**:
- [ ] APNs certificate uploaded to Firebase Console
- [ ] Background Modes enabled in Xcode
- [ ] Permission granted by user
- [ ] Device not in Do Not Disturb mode
- [ ] Test on physical device (not simulator for production)

---

### Issue: Android 13+ not showing notifications

**Cause**: `POST_NOTIFICATIONS` permission not granted.

**Solution**:
```dart
// Request permission explicitly
final settings = await messaging.requestPermission();
if (settings.authorizationStatus == AuthorizationStatus.denied) {
  // Guide user to settings
}
```

---

## Platform-Specific Testing Checklist

### iOS Testing
- [ ] Test on physical device
- [ ] Verify APNs certificate in Firebase Console
- [ ] Test with permission allowed
- [ ] Test with permission denied
- [ ] Test foreground, background, terminated states
- [ ] Verify sound/badge/banner settings

### Android Testing
- [ ] Test on Android 12 and below
- [ ] Test on Android 13+
- [ ] Verify `google-services.json` is present
- [ ] Test with permission allowed (Android 13+)
- [ ] Test with permission denied (Android 13+)
- [ ] Test notification channels
- [ ] Verify foreground, background, terminated states

---

## Summary: What You Need to Do

### For Each Platform

#### iOS Setup
1. Configure APNs in Firebase Console
2. Enable Background Modes in Xcode
3. Request permission in code
4. Handle permission states (granted/denied/provisional)
5. Test on physical device

#### Android Setup
1. Add `google-services.json` to `android/app/`
2. Configure notification channel in `AndroidManifest.xml`
3. Handle Android 13+ permission request
4. Test on different Android versions

#### Both Platforms
1. Initialize Firebase in app startup
2. Call `NotificationService.initialize()`
3. Listen to notification stream
4. Handle navigation from notifications
5. Test all three states: foreground, background, terminated
6. Implement token refresh handling
7. Send tokens to your backend

---

## When to Do What

| Scenario | Action | Platform |
|----------|--------|----------|
| **App First Launch** | Request permission | iOS, Android 13+ |
| **Permission Denied** | Show settings guidance | Both |
| **Token Received** | Send to backend | Both |
| **Token Refreshed** | Update backend | Both |
| **Foreground Notification** | Show in-app UI | Both |
| **Background Notification** | Process data, log | Both |
| **Terminated Notification** | Deep link on launch | Both |
| **User Taps Notification** | Navigate to content | Both |

---

## Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [flutter_local_notifications Package](https://pub.dev/packages/flutter_local_notifications)
- [FCM Server API](https://firebase.google.com/docs/cloud-messaging/server)
- [iOS APNs Configuration](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)

---

**Last Updated**: January 2026  
**Project**: Flutter Firebase Push Notification Template  
**Architecture**: Clean Architecture with Riverpod

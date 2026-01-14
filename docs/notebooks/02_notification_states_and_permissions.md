# 📲 Notification States & Platform Permissions

> **Journey Step 2:** Understanding how notifications behave across different app states and platforms

---

## 📋 Table of Contents
1. [Notification States Overview](#notification-states-overview)
2. [iOS Permissions & Behavior](#ios-permissions--behavior)
3. [Android Permissions & Behavior](#android-permissions--behavior)
4. [State-by-State Handling](#state-by-state-handling)
5. [Permission Request Flow](#permission-request-flow)

---

## 🎯 Notification States Overview

Firebase Cloud Messaging handles notifications differently based on three app states:

| State | Description | User Action | Common Use Case |
|-------|-------------|-------------|-----------------|
| **Foreground** | App is open and active | Currently using app | Show in-app banner |
| **Background** | App is minimized/in background | Switched to another app | System notification tray |
| **Terminated** | App is completely closed | Force closed or not running | Launch app from notification |

---

## 🍎 iOS Permissions & Behavior

### Permission System

iOS requires **explicit user permission** for notifications through a one-time system dialog.

#### First-Time Permission Request

```dart
await FirebaseMessaging.instance.requestPermission(
  alert: true,      // Show visual notifications
  badge: true,      // Update app icon badge
  sound: true,      // Play notification sound
  announcement: false,  // Siri announcements
  carPlay: false,   // CarPlay notifications
  criticalAlert: false, // Bypass Do Not Disturb (requires special entitlement)
  provisional: false,   // Silent notifications without dialog
);
```

**System Dialog Appears:**
```
"YourApp" Would Like to Send You Notifications

Notifications may include alerts, sounds, and icon badges.

[Don't Allow]  [Allow]
```

⚠️ **Important:** This dialog appears **only once**. Cannot be shown again programmatically.

---

### Permission States

#### 1. ✅ Authorized (Permission Granted)

**User Action:** Tapped "Allow"

**Result:**
- FCM token generated ✅
- APNs token received ✅
- Notifications delivered ✅

**What you can receive:**
```dart
// All notification types work
FirebaseMessaging.onMessage.listen((message) {
  // Foreground notifications
});

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // Background → Foreground
});

FirebaseMessaging.instance.getInitialMessage().then((message) {
  // Terminated → Foreground
});
```

**Notification Appearance:**
- 📱 Lock screen: YES
- 📱 Notification Center: YES
- 📱 Banner: YES
- 🔔 Sound: YES
- 🔴 Badge: YES

---

#### 2. ❌ Denied (Permission Denied)

**User Action:** Tapped "Don't Allow"

**Result:**
- FCM token: `null` ❌
- APNs token: Not generated ❌
- Notifications: NOT delivered ❌

**Code behavior:**
```dart
final token = await FirebaseMessaging.instance.getToken();
print(token); // null

NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
print(settings.authorizationStatus); // AuthorizationStatus.denied
```

**How users can re-enable:**
1. Go to **Settings** → **Notifications** → **[Your App]**
2. Toggle **"Allow Notifications"** ON
3. FCM token will generate on next app launch

⚠️ **Your app cannot re-request permission programmatically!**

---

#### 3. ⏸️ Not Determined (Never Asked)

**User Action:** First app launch, permission not requested yet

**Result:**
- FCM token: `null` ❌
- Permission can be requested ✅

```dart
NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
  // Show educational screen before requesting
  await showNotificationExplanation();
  
  // Then request
  await FirebaseMessaging.instance.requestPermission();
}
```

---

#### 4. 🔕 Provisional (Silent Notifications - iOS 12+)

**Special Mode:** Deliver notifications silently without asking permission

```dart
await FirebaseMessaging.instance.requestPermission(
  provisional: true,
);
```

**Behavior:**
- ✅ Notifications appear in Notification Center
- ❌ No banners or sounds
- ❌ No interruption to user
- ✅ User can enable full notifications from Notification Center

**Use case:** Trial notifications without permission dialog

---

### iOS Permission Options Explained

| Option | Default | Description | Effect if Disabled |
|--------|---------|-------------|-------------------|
| `alert` | true | Visual notifications | No banners or alerts |
| `badge` | true | App icon badge number | No red badge on icon |
| `sound` | true | Notification sounds | Silent notifications |
| `announcement` | false | Siri reads notifications | No voice announcements |
| `carPlay` | false | Show on CarPlay | Not shown in car |
| `criticalAlert` | false | Override silent mode | Requires Apple approval |
| `provisional` | false | Silent trial mode | Shows normal permission |

---

### iOS Notification Behavior by State

| App State | Notification Delivered? | Handler | Banner Shown? | Sound | Badge |
|-----------|------------------------|---------|---------------|-------|-------|
| **Foreground** | ✅ Yes | `onMessage` | ❌ No* | ❌ No* | ❌ No* |
| **Background** | ✅ Yes | `onBackgroundMessage` | ✅ Yes | ✅ Yes | ✅ Yes |
| **Terminated** | ✅ Yes | `getInitialMessage` | ✅ Yes | ✅ Yes | ✅ Yes |

*Can be customized with `flutter_local_notifications` plugin

---

## 🤖 Android Permissions & Behavior

### Permission System Evolution

Android's notification permission system changed significantly in Android 13 (API 33).

---

### Android 12 and Below (API ≤ 32)

#### ✅ Notifications Enabled by Default

**No Permission Dialog!**

```dart
await FirebaseMessaging.instance.requestPermission();
// Returns authorized immediately - no user interaction needed
```

**Behavior:**
- FCM token generated ✅
- Notifications work immediately ✅
- Users can disable in Settings manually

**User control:**
- Settings → Apps → [Your App] → Notifications
- Can disable notifications, but app doesn't know

---

### Android 13+ (API ≥ 33)

#### 📋 Runtime Permission Required

Similar to iOS - shows permission dialog.

**AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**Permission Dialog:**
```
Allow [App Name] to send you notifications?

[Don't allow]  [Allow]
```

**Code:**
```dart
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();

if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  print('✅ Permission granted');
} else if (settings.authorizationStatus == AuthorizationStatus.denied) {
  print('❌ Permission denied');
}
```

---

### Android Permission States

#### 1. ✅ Authorized (Permission Granted)

**Android 12-:** Auto-granted by default
**Android 13+:** User tapped "Allow"

**Result:**
- FCM token: Generated ✅
- **Notification messages:** Shown in system tray ✅
- **Data messages:** Delivered ✅

```dart
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token'); // Always generated when granted
```

---

#### 2. ❌ Denied (Permission Denied - Android 13+ only)

**User Action:** Tapped "Don't allow"

**Result:**
- FCM token: **Still generated!** ✅ (Different from iOS!)
- **Notification messages:** NOT shown ❌
- **Data-only messages:** Still delivered ✅

**Key Difference from iOS:**

```dart
// Even if permission denied, token exists!
final token = await FirebaseMessaging.instance.getToken();
print(token); // "eDx5...token here" (NOT null!)

// But notification won't show in system tray
// Data messages still arrive:
FirebaseMessaging.onMessage.listen((message) {
  // This still works!
  final data = message.data;
  // Can update UI, sync data, etc.
});
```

**Use cases when denied:**
- Silent data synchronization
- In-app updates without notifications
- Background data fetching

**How users can re-enable:**
1. Settings → Apps → [Your App] → Notifications
2. Enable notifications

---

### Android Notification Channels (API 26+)

Required for Android 8.0 and above.

**What are channels?**
- Categories for different notification types
- Users can customize per channel
- Must create before sending notifications

**Example:**
```dart
// Create notification channel (usually in MainActivity.kt)
val channel = NotificationChannel(
    "high_importance_channel",
    "Important Notifications",
    NotificationManager.IMPORTANCE_HIGH
).apply {
    description = "Used for important app notifications"
    enableLights(true)
    enableVibration(true)
}

val manager = getSystemService(NotificationManager::class.java)
manager.createNotificationChannel(channel)
```

**User control per channel:**
- Importance level (Silent, Low, Medium, High, Urgent)
- Sound and vibration
- Badge visibility
- Override Do Not Disturb

---

### Android Notification Behavior by State

| App State | Notification Delivered? | Data Messages? | Handler | System Tray | Sound | Badge |
|-----------|------------------------|----------------|---------|-------------|-------|-------|
| **Foreground** | ✅ Yes | ✅ Yes | `onMessage` | ❌ No* | ❌ No* | ❌ No* |
| **Background** | ✅ Yes | ✅ Yes | `onBackgroundMessage` | ✅ Yes | ✅ Yes | ✅ Yes |
| **Terminated** | ✅ Yes | ✅ Yes | `getInitialMessage` | ✅ Yes | ✅ Yes | ✅ Yes |

*Can be customized with `flutter_local_notifications`

---

## 🎬 State-by-State Handling

### 1️⃣ Foreground State

**When:** User is actively using the app

**Behavior:**
- Notification data received ✅
- System UI notification NOT shown by default
- Full control over presentation

**Handler:**
```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  print('📱 Foreground message: ${message.notification?.title}');
  print('📦 Data: ${message.data}');
  
  // Custom UI handling
  showCustomBanner(
    title: message.notification?.title,
    body: message.notification?.body,
    onTap: () => navigateToScreen(message.data),
  );
});
```

**Common use cases:**
- Show in-app banner/snackbar
- Update UI immediately
- Display custom dialog
- Real-time data updates

---

### 2️⃣ Background State

**When:** App is minimized or screen is locked

**Behavior:**
- System notification shown automatically ✅
- Background handler executes
- Limited execution time (~30 seconds)
- Sound/vibration plays

**Handler:**
```dart
// MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.notification?.title}');
  
  // ✅ Can do: Update database, sync data, log events
  await updateLocalDatabase(message.data);
  
  // ❌ Cannot do: Access UI, use BuildContext, long operations
}

// Register in main()
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

**Restrictions:**
- Must be top-level function (not inside class)
- Must have `@pragma('vm:entry-point')` annotation
- Complete within ~30 seconds
- Cannot access UI

**User experience:**
- Sees notification in tray
- Hears sound (if enabled)
- Taps → Opens app

---

### 3️⃣ Terminated State

**When:** App is completely closed (force closed or never launched)

**Behavior:**
- System notification shown ✅
- Background handler executes
- User taps notification to launch app
- `getInitialMessage()` contains notification data

**Handler:**
```dart
Future<void> handleTerminatedState() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  
  if (initialMessage != null) {
    print('🚀 App launched from notification');
    print('📦 Data: ${initialMessage.data}');
    
    // Navigate to specific screen
    final route = getRouteFromPayload(initialMessage.data);
    navigateToRoute(route);
  }
}

// Call in app startup
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await handleTerminatedState();
  
  runApp(MyApp());
}
```

**Important:** Check `getInitialMessage()` during app initialization, not later!

---

### 4️⃣ Background → Foreground Transition

**When:** User taps notification while app is in background

**Handler:**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  print('📲 App opened from background');
  print('📦 Data: ${message.data}');
  
  // Navigate to specific screen
  navigateToScreen(message.data);
});
```

**Flow:**
1. User receives notification (app in background)
2. User taps notification
3. App comes to foreground
4. `onMessageOpenedApp` triggered
5. Navigate to target screen

---

## 🔐 Permission Request Flow

### Recommended Implementation

```dart
Future<void> requestNotificationPermission() async {
  final messaging = FirebaseMessaging.instance;

  // Check current permission status
  NotificationSettings settings = await messaging.getNotificationSettings();

  if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
    // Permission not asked yet - show explanation
    final shouldRequest = await showPermissionRationale();
    
    if (!shouldRequest) return;
    
    // Request permission
    settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  // Handle result
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');
    
    final token = await messaging.getToken();
    print('FCM Token: $token');
    
    // Send token to backend
    await sendTokenToServer(token);
    
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('🔕 User granted provisional permission');
    
  } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print('❌ User denied permission');
    
    // Show guide to enable in settings
    showEnableNotificationsGuide();
  }
}
```

### Permission Rationale Dialog

**Best practice:** Explain WHY before requesting

```dart
Future<bool> showPermissionRationale() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Stay Updated'),
      content: Text(
        'Get notified about:\n'
        '• New collections and products\n'
        '• Special offers and discounts\n'
        '• Order status updates'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Not Now'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Enable'),
        ),
      ],
    ),
  ) ?? false;
}
```

---

## 📊 Platform Comparison Table

| Feature | iOS | Android 12- | Android 13+ |
|---------|-----|-------------|-------------|
| **Permission Dialog** | Yes (once) | No | Yes (once) |
| **Default State** | Not determined | Granted | Not determined |
| **FCM Token if Denied** | `null` | Generated | Generated |
| **Data Messages if Denied** | Not delivered | Delivered | Delivered |
| **Re-request Permission** | No (settings only) | N/A | No (settings only) |
| **Provisional Mode** | Yes | No | No |
| **Notification Channels** | No | Yes (API 26+) | Yes |

---

## 🎯 Best Practices

### 1. Context Before Permission

✅ **DO:** Explain benefits before requesting
❌ **DON'T:** Request immediately on app launch

### 2. Graceful Degradation

```dart
// Handle permission denial gracefully
if (token == null) {
  // Offer alternative (email, in-app messages, manual refresh)
  showAlternativeOptions();
} else {
  enableRealtimeFeatures();
}
```

### 3. Permission Status Checking

```dart
// Check before showing permission-dependent UI
Future<bool> hasNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.getNotificationSettings();
  return settings.authorizationStatus == AuthorizationStatus.authorized;
}
```

### 4. Guide to Settings

```dart
void showEnableNotificationsGuide() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enable Notifications'),
      content: Text(
        'To receive notifications:\n\n'
        '1. Go to Settings\n'
        '2. Select Notifications\n'
        '3. Find ${App.name}\n'
        '4. Toggle Allow Notifications ON'
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Open app settings (platform-specific)
            AppSettings.openAppSettings();
          },
          child: Text('Open Settings'),
        ),
      ],
    ),
  );
}
```

---

## 📚 Next Steps

- ✅ Understanding notification states complete!
- 📍 Next: [Clean Architecture Implementation](./03_implementation_guide.md)
- 📍 Then: [Testing & Debugging](./04_testing_guide.md)

---

## 🔗 References

- [FCM Message Types](https://firebase.google.com/docs/cloud-messaging/concept-options)
- [iOS Notification Settings](https://developer.apple.com/documentation/usernotifications/asking_permission_to_use_notifications)
- [Android Runtime Permissions](https://developer.android.com/training/permissions/requesting)

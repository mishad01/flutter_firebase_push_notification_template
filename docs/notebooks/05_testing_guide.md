# 🧪 Testing & Debugging Guide

> **Journey Step 5:** Ensuring your notification system works flawlessly

---

## 📋 Table of Contents
1. [Testing Strategies](#testing-strategies)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [Manual Testing Checklist](#manual-testing-checklist)
5. [Debugging Tools](#debugging-tools)
6. [Common Issues & Solutions](#common-issues--solutions)

---

## 🎯 Testing Strategies

### Testing Pyramid for Notifications

```
        ┌─────────────────┐
        │   Manual Tests  │ ← Device testing, real notifications
        └─────────────────┘
       ┌───────────────────┐
       │ Integration Tests │ ← Service → Repository → Use Case
       └───────────────────┘
    ┌─────────────────────────┐
    │      Unit Tests         │ ← Individual components
    └─────────────────────────┘
```

---

## 🔬 Unit Testing

### Test Domain Entities

```dart
// test/domain/entities/notification_entity_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/src/domain/entities/notification_entity.dart';
import 'package:your_app/src/domain/entities/notification_payload_entity.dart';

void main() {
  group('NotificationEntity', () {
    test('should create entity with all fields', () {
      // Arrange
      final payload = NotificationPayloadEntity(
        type: NotificationType.collection,
        collectionId: '123',
        collectionTitle: 'New Arrivals',
        checkOutUrl: 'https://example.com',
      );

      // Act
      final notification = NotificationEntity(
        title: 'Test Title',
        body: 'Test Body',
        payload: payload,
      );

      // Assert
      expect(notification.title, 'Test Title');
      expect(notification.body, 'Test Body');
      expect(notification.payload, payload);
      expect(notification.payload?.type, NotificationType.collection);
    });

    test('should create entity with null payload', () {
      // Act
      final notification = NotificationEntity(
        title: 'Test',
        body: 'Body',
        payload: null,
      );

      // Assert
      expect(notification.payload, isNull);
    });
  });

  group('NotificationPayloadEntity', () {
    test('should create payload with correct type', () {
      // Act
      final payload = NotificationPayloadEntity(
        type: NotificationType.cart,
        collectionId: '',
        collectionTitle: '',
        checkOutUrl: '',
      );

      // Assert
      expect(payload.type, NotificationType.cart);
    });
  });
}
```

---

### Test Data Models

```dart
// test/data/models/notification_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/src/data/models/notification_model.dart';

void main() {
  group('NotificationPayloadModel', () {
    test('should parse JSON correctly', () {
      // Arrange
      final json = {
        'type': 'collection',
        'collectionId': '123',
        'collectionTitle': 'New Arrivals',
        'checkOutUrl': 'https://example.com/checkout',
      };

      // Act
      final model = NotificationPayloadModel.fromJson(json);

      // Assert
      expect(model.type, NotificationType.collection);
      expect(model.collectionId, '123');
      expect(model.collectionTitle, 'New Arrivals');
      expect(model.checkOutUrl, 'https://example.com/checkout');
    });

    test('should handle missing optional fields with defaults', () {
      // Arrange
      final json = {'type': 'home'};

      // Act
      final model = NotificationPayloadModel.fromJson(json);

      // Assert
      expect(model.type, NotificationType.home);
      expect(model.collectionId, '');
      expect(model.collectionTitle, '');
      expect(model.checkOutUrl, '');
    });

    test('should map unknown type to default (home)', () {
      // Arrange
      final json = {'type': 'unknown_type'};

      // Act
      final model = NotificationPayloadModel.fromJson(json);

      // Assert
      expect(model.type, NotificationType.home);
    });

    test('should handle case-insensitive type', () {
      // Arrange
      final json = {'type': 'COLLECTION'};

      // Act
      final model = NotificationPayloadModel.fromJson(json);

      // Assert
      expect(model.type, NotificationType.collection);
    });
  });
}
```

---

### Test Repository Implementation

```dart
// test/data/repositories/notification_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:your_app/src/data/repositories/notification_repository_impl.dart';
import 'package:your_app/src/data/services/notification/notification_service.dart';
import 'package:your_app/src/data/models/notification_model.dart';

@GenerateMocks([NotificationService])
import 'notification_repository_impl_test.mocks.dart';

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationService mockService;

  setUp(() {
    mockService = MockNotificationService();
    repository = NotificationRepositoryImpl(mockService);
  });

  group('NotificationRepositoryImpl', () {
    test('should initialize notification service', () async {
      // Arrange
      when(mockService.initialize()).thenAnswer((_) async => {});

      // Act
      await repository.initializeNotification();

      // Assert
      verify(mockService.initialize()).called(1);
    });

    test('should get FCM token from service', () async {
      // Arrange
      const testToken = 'test_fcm_token_123';
      when(mockService.getFcmToken()).thenAnswer((_) async => testToken);

      // Act
      final token = await repository.getFcmToken();

      // Assert
      expect(token, testToken);
      verify(mockService.getFcmToken()).called(1);
    });

    test('should return null if no FCM token', () async {
      // Arrange
      when(mockService.getFcmToken()).thenAnswer((_) async => null);

      // Act
      final token = await repository.getFcmToken();

      // Assert
      expect(token, isNull);
    });

    test('should stream notifications from service', () async {
      // Arrange
      final testNotification = NotificationModel(
        title: 'Test',
        body: 'Body',
        payload: null,
      );
      final stream = Stream.value(testNotification);
      when(mockService.onNotification).thenAnswer((_) => stream);

      // Act
      final result = repository.onNotification;

      // Assert
      expect(result, emits(testNotification));
    });
  });
}
```

---

### Test Use Cases

```dart
// test/domain/use_cases/notification_use_case_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:your_app/src/domain/repositories/notification_repository.dart';
import 'package:your_app/src/domain/use_cases/notification_use_case.dart';
import 'package:your_app/src/domain/entities/notification_entity.dart';

@GenerateMocks([NotificationRepository])
import 'notification_use_case_test.mocks.dart';

void main() {
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
  });

  group('InitializaNotificationUseCase', () {
    test('should call repository initialize method', () async {
      // Arrange
      final useCase = InitializaNotificationUseCase(mockRepository);
      when(mockRepository.initializeNotification())
          .thenAnswer((_) async => {});

      // Act
      await useCase.call();

      // Assert
      verify(mockRepository.initializeNotification()).called(1);
    });
  });

  group('GetNotificationStreamUseCase', () {
    test('should return notification stream from repository', () {
      // Arrange
      final useCase = GetNotificationStreamUseCase(mockRepository);
      final testNotification = NotificationEntity(
        title: 'Test',
        body: 'Body',
        payload: null,
      );
      final stream = Stream.value(testNotification);
      when(mockRepository.onNotification).thenAnswer((_) => stream);

      // Act
      final result = useCase.call();

      // Assert
      expect(result, emits(testNotification));
      verify(mockRepository.onNotification).called(1);
    });
  });

  group('GetFcmTokenUseCase', () {
    test('should return token from repository', () async {
      // Arrange
      final useCase = GetFcmTokenUseCase(mockRepository);
      const testToken = 'fcm_token_xyz';
      when(mockRepository.getFcmToken()).thenAnswer((_) async => testToken);

      // Act
      final token = await useCase.call();

      // Assert
      expect(token, testToken);
      verify(mockRepository.getFcmToken()).called(1);
    });
  });

  group('GetNotificationPayloadUseCase', () {
    test('should return current payload from repository', () {
      // Arrange
      final useCase = GetNotificationPayloadUseCase(mockRepository);
      final testPayload = NotificationPayloadEntity(
        type: NotificationType.collection,
        collectionId: '123',
        collectionTitle: 'Test',
        checkOutUrl: '',
      );
      when(mockRepository.payload).thenReturn(testPayload);

      // Act
      final payload = useCase.call();

      // Assert
      expect(payload, testPayload);
      verify(mockRepository.payload).called(1);
    });
  });
}
```

---

## 🔗 Integration Testing

### Test Notification Flow

```dart
// integration_test/notification_flow_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:your_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Flow Integration Test', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    testWidgets('should initialize FCM and get token', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Wait for initialization
      await tester.pump(const Duration(seconds: 2));

      // Get FCM token
      final token = await FirebaseMessaging.instance.getToken();

      // Assert token exists
      expect(token, isNotNull);
      expect(token!.isNotEmpty, true);

      print('✅ FCM Token: $token');
    });

    testWidgets('should request notification permission', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Request permission
      final settings = await FirebaseMessaging.instance.requestPermission();

      // Assert
      expect(settings.authorizationStatus, isNotNull);
      print('✅ Permission status: ${settings.authorizationStatus}');
    });
  });
}
```

---

## ✅ Manual Testing Checklist

### iOS Testing

#### Foreground State
- [ ] App is open and active
- [ ] Send test notification from Firebase Console
- [ ] Verify notification appears (custom UI or banner)
- [ ] Tap notification
- [ ] Verify navigation to correct screen
- [ ] Check FCM token logged in console

#### Background State
- [ ] Minimize app (home button)
- [ ] Send test notification
- [ ] Verify notification appears in notification center
- [ ] Verify sound plays (if enabled)
- [ ] Tap notification
- [ ] App opens to correct screen
- [ ] Verify badge number updates

#### Terminated State
- [ ] Force close app (swipe up in app switcher)
- [ ] Send test notification
- [ ] Verify notification appears
- [ ] Tap notification
- [ ] App launches to correct screen
- [ ] Verify `getInitialMessage()` handled

#### Permission States
- [ ] First install - permission dialog shows
- [ ] Tap "Allow" - token generated
- [ ] Uninstall and reinstall - dialog shows again
- [ ] Tap "Don't Allow" - token is null
- [ ] Check Settings app - can manually enable

---

### Android Testing

#### Android 12 and Below
- [ ] Install app
- [ ] No permission dialog shows
- [ ] FCM token generated automatically
- [ ] Notifications work immediately
- [ ] Verify in Settings → Notifications

#### Android 13+
- [ ] Install app
- [ ] Permission dialog shows
- [ ] Tap "Allow" - token generated
- [ ] Tap "Don't allow" - token still generated (!)
- [ ] Notifications don't show (but data messages work)

#### Foreground State
- [ ] App is open
- [ ] Send notification
- [ ] Custom UI shows (if implemented)
- [ ] Tap → Navigate correctly

#### Background State
- [ ] Minimize app
- [ ] Send notification
- [ ] System notification shows
- [ ] Sound/vibration works
- [ ] Tap → Opens to screen

#### Terminated State
- [ ] Force close app
- [ ] Send notification
- [ ] Notification appears
- [ ] Tap → Launches app to screen

---

### Cross-Platform Tests

#### Notification Types
- [ ] Collection notification → Collection page
- [ ] Cart notification → Cart page
- [ ] Home notification → Home page
- [ ] Unknown type → Default (Home)

#### Authentication Guards
- [ ] Cart notification (protected route)
  - Logged in → Direct navigation
  - Not logged in → Login page → Cart after login
- [ ] Collection notification (public route)
  - Works regardless of auth state

#### Data Payload
- [ ] Notification with all fields
- [ ] Notification with missing fields
- [ ] Notification without data (notification-only)
- [ ] Data-only message (no notification field)

#### Edge Cases
- [ ] Rapid multiple notifications
- [ ] Very long notification text
- [ ] Special characters in payload
- [ ] Invalid JSON in data
- [ ] Network offline when receiving

---

## 🛠️ Debugging Tools

### 1. FCM Token Debugger

```dart
// Add to your app for testing
class FcmTokenDebugger extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Token Debugger')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () async {
                final token = await ref
                    .read(getFcmTokenUseCaseProvider)
                    .call();
                print('FCM Token: $token');
                
                // Copy to clipboard
                await Clipboard.setData(ClipboardData(text: token ?? ''));
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Token copied!')),
                );
              },
              child: Text('Get & Copy FCM Token'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final settings = await FirebaseMessaging.instance
                    .getNotificationSettings();
                print('Permission: ${settings.authorizationStatus}');
                
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Permission Status'),
                    content: Text(
                      'Status: ${settings.authorizationStatus}\n'
                      'Alert: ${settings.alert}\n'
                      'Badge: ${settings.badge}\n'
                      'Sound: ${settings.sound}',
                    ),
                  ),
                );
              },
              child: Text('Check Permission'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(getNotificationStreamUseCaseProvider)
                    .call()
                    .listen((notification) {
                  print('📬 Notification Received:');
                  print('  Title: ${notification.title}');
                  print('  Body: ${notification.body}');
                  print('  Type: ${notification.payload?.type}');
                  print('  Data: ${notification.payload}');
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Listening to notifications...')),
                );
              },
              child: Text('Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 2. Notification Logger

```dart
// lib/src/core/logger/notification_logger.dart

class NotificationLogger {
  static final List<String> _logs = [];

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';
    _logs.add(entry);
    print(entry);
    
    // Keep only last 100 logs
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
  }

  static List<String> getLogs() => List.unmodifiable(_logs);

  static void clear() => _logs.clear();

  static String export() => _logs.join('\n');
}

// Usage in service
Log.info('Notification received');
NotificationLogger.log('Notification received: ${message.messageId}');
```

---

### 3. Firebase Console Test

**Send test notification:**

1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter your FCM token
4. Configure notification:
   ```
   Title: Test Notification
   Body: This is a test
   ```
5. Add data payload:
   ```json
   {
     "type": "collection",
     "collectionId": "test_123",
     "collectionTitle": "Test Collection",
     "checkOutUrl": "https://example.com"
   }
   ```
6. Click "Test"

---

### 4. Android Debug Bridge (ADB)

**View notification logs:**

```bash
# Filter FCM logs
adb logcat | grep FCM

# Filter app logs
adb logcat | grep "your.package.name"

# Clear and follow
adb logcat -c && adb logcat | grep -E "FCM|Firebase|Notification"
```

**Simulate notification:**

```bash
# Using ADB to send intent
adb shell am start -a android.intent.action.VIEW \
  -d "yourapp://notification?type=collection&id=123"
```

---

### 5. iOS Console (Xcode)

**View logs:**

1. Connect device
2. Open Xcode → Window → Devices and Simulators
3. Select device → Open Console
4. Filter: `FCM` or `Firebase`

**Debug with breakpoints:**

1. Set breakpoint in `NotificationServiceImpl`
2. Send test notification
3. Step through code
4. Inspect variables

---

## 🐛 Common Issues & Solutions

### Issue 1: FCM Token is Null

**Symptoms:**
```dart
final token = await FirebaseMessaging.instance.getToken();
print(token); // null
```

**Possible Causes & Solutions:**

✅ **Firebase not initialized**
```dart
// Ensure this runs first
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

✅ **iOS - Permission denied**
```dart
// Check permission status
final settings = await FirebaseMessaging.instance.getNotificationSettings();
if (settings.authorizationStatus == AuthorizationStatus.denied) {
  print('User denied permission - token will be null');
}
```

✅ **Configuration files missing**
- Android: Check `google-services.json` in `android/app/`
- iOS: Check `GoogleService-Info.plist` in Xcode project

✅ **Wrong package name / Bundle ID**
- Verify matches Firebase Console configuration

---

### Issue 2: Notifications Not Showing

**Android:**

✅ **Check permission (Android 13+)**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

✅ **Notification channel not created**
```dart
// Create channel before sending notifications
const channel = AndroidNotificationChannel(...);
await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<...>()
    ?.createNotificationChannel(channel);
```

✅ **Check Settings**
- Settings → Apps → Your App → Notifications → Enabled

**iOS:**

✅ **Permission denied**
- Settings → Your App → Notifications → Allow

✅ **APNs certificate not uploaded**
- Firebase Console → Project Settings → Cloud Messaging
- Upload APNs key

✅ **Testing on simulator**
- Push notifications don't work on iOS simulator
- Use real device

---

### Issue 3: Background Handler Not Triggered

**Symptoms:**
```dart
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  print('Not printing!'); // Not called
}
```

**Solutions:**

✅ **Must be top-level function**
```dart
// ❌ Wrong - inside class
class MyService {
  static Future<void> handler(RemoteMessage message) async { }
}

// ✅ Correct - top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message');
}
```

✅ **Register before getting token**
```dart
// Must be before requestPermission() or getToken()
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

✅ **Android - Process may be killed**
- Background handler has limited time (~30 seconds)
- Don't perform long operations

---

### Issue 4: Navigation Not Working

**Symptoms:**
- Notification received
- Tap notification
- Nothing happens or wrong screen

**Solutions:**

✅ **Context not available**
```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final context = navigatorKey.currentContext;
  if (context == null) {
    print('Context not ready!');
    return;
  }
  
  context.go('/screen');
});
```

✅ **Called too early**
```dart
// Wait for app to be ready
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.go('/screen');
});
```

✅ **Router not initialized**
```dart
// Ensure router is created before navigation
final router = ref.read(goRouterProvider);
router.go('/screen');
```

---

### Issue 5: Data Payload Not Parsing

**Symptoms:**
```dart
NotificationPayloadModel.fromJson(message.data); // Exception
```

**Solutions:**

✅ **Wrap in try-catch**
```dart
try {
  final payload = NotificationPayloadModel.fromJson(message.data);
} catch (e) {
  Log.error('Parse error: $e');
  Log.error('Data: ${message.data}');
  return null;
}
```

✅ **Check data types**
```dart
// Firebase sends everything as String!
final data = {
  'type': 'collection',
  'collectionId': '123', // String, not int
};
```

✅ **Validate before parsing**
```dart
if (message.data.isEmpty) {
  return null; // No payload
}

if (!message.data.containsKey('type')) {
  Log.warning('Missing required field: type');
  return null;
}
```

---

### Issue 6: Multiple Notifications Stacking

**Symptoms:**
- User receives notification
- Taps it multiple times
- Navigation happens multiple times

**Solution:**

```dart
bool _isHandlingNotification = false;

FirebaseMessaging.onMessageOpenedApp.listen((message) async {
  if (_isHandlingNotification) return;
  
  _isHandlingNotification = true;
  
  try {
    await handleNotification(message);
  } finally {
    _isHandlingNotification = false;
  }
});
```

---

## 📊 Testing Report Template

```markdown
## Notification Testing Report

**Date:** YYYY-MM-DD
**Tester:** Your Name
**App Version:** 1.0.0
**Device:** iPhone 14 Pro / Pixel 7

### ✅ Passed Tests
- [ ] FCM token generation
- [ ] Permission request dialog
- [ ] Foreground notification
- [ ] Background notification
- [ ] Terminated state notification
- [ ] Navigation from notification
- [ ] Data payload parsing

### ❌ Failed Tests
- Issue: Description
- Steps to reproduce
- Expected vs Actual

### 📝 Notes
- Any observations
- Performance issues
- Suggestions
```

---

## 📚 Next Steps

- ✅ Testing complete!
- 📍 Next: [Production Deployment](./06_deployment_guide.md)
- 📍 Then: [Monitoring & Analytics](./07_monitoring_guide.md)

---

## 🔗 References

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

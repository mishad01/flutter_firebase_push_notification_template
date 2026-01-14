# 🏗️ Clean Architecture Implementation

> **Journey Step 3:** Implementing FCM with Clean Architecture principles in your codebase

---

## 📋 Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Layer-by-Layer Implementation](#layer-by-layer-implementation)
3. [Code Walkthrough](#code-walkthrough)
4. [Dependency Injection](#dependency-injection)
5. [Integration with App](#integration-with-app)

---

## 🎯 Architecture Overview

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Widgets, Pages, Providers                       │  │
│  │  - Router integration                             │  │
│  │  - UI notifications                               │  │
│  │  - Navigation logic                               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│                    Domain Layer                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Entities, Repository Interfaces, Use Cases      │  │
│  │  - NotificationEntity                             │  │
│  │  - NotificationPayloadEntity                      │  │
│  │  - NotificationRepository (abstract)              │  │
│  │  - Use Cases (initialize, stream, get token)     │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│                     Data Layer                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Models, Services, Repository Implementation     │  │
│  │  - NotificationModel (extends Entity)            │  │
│  │  - NotificationService (abstract)                 │  │
│  │  - NotificationServiceImpl (Firebase)             │  │
│  │  - NotificationRepositoryImpl                     │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                         ↕
              ┌──────────────────────┐
              │  Firebase Messaging  │
              └──────────────────────┘
```

### Key Principles

1. **Dependency Rule:** Inner layers don't depend on outer layers
2. **Domain Layer:** No external dependencies (Firebase, packages)
3. **Data Layer:** Implements domain contracts with Firebase
4. **Presentation Layer:** Consumes domain through use cases

---

## 🔨 Layer-by-Layer Implementation

### Step 1: Domain Layer - Entities

#### NotificationPayloadEntity

```dart
// lib/src/domain/entities/notification_payload_entity.dart

enum NotificationType {
  collection,
  cart,
  home,
}

class NotificationPayloadEntity {
  NotificationPayloadEntity({
    required this.type,
    required this.collectionId,
    required this.collectionTitle,
    required this.checkOutUrl,
  });

  final NotificationType type;
  final String collectionId;
  final String collectionTitle;
  final String checkOutUrl;
}
```

**Why?**
- Represents business data (no Firebase types)
- Type-safe enum for routing
- Contains all navigation data

---

#### NotificationEntity

```dart
// lib/src/domain/entities/notification_entity.dart

import 'notification_payload_entity.dart';

class NotificationEntity {
  NotificationEntity({
    this.title,
    this.body,
    this.payload,
  });

  final String? title;
  final String? body;
  final NotificationPayloadEntity? payload;
}
```

**Why?**
- Combines visible notification with custom data
- Nullable fields (not all notifications have all data)
- Platform-agnostic

---

### Step 2: Domain Layer - Repository Interface

```dart
// lib/src/domain/repositories/notification_repository.dart

import '../entities/notification_entity.dart';
import '../entities/notification_payload_entity.dart';

abstract class NotificationRepository {
  /// Initialize notification system
  Future<void> initializeNotification();
  
  /// Get FCM token
  Future<String?> getFcmToken();
  
  /// Get current payload
  NotificationPayloadEntity? get payload;
  
  /// Stream of incoming notifications
  Stream<NotificationEntity> get onNotification;
}
```

**Why?**
- Contract for what notifications can do
- No implementation details
- Domain layer depends on this abstraction

---

### Step 3: Domain Layer - Use Cases

```dart
// lib/src/domain/use_cases/notification_use_case.dart

import '../entities/notification_entity.dart';
import '../entities/notification_payload_entity.dart';
import '../repositories/notification_repository.dart';

/// Initialize notification system
class InitializaNotificationUseCase {
  InitializaNotificationUseCase(this._repository);
  
  final NotificationRepository _repository;

  Future<void> call() async {
    return _repository.initializeNotification();
  }
}

/// Stream notifications
class GetNotificationStreamUseCase {
  GetNotificationStreamUseCase(this._repository);
  
  final NotificationRepository _repository;

  Stream<NotificationEntity> call() {
    return _repository.onNotification;
  }
}

/// Get FCM token
class GetFcmTokenUseCase {
  GetFcmTokenUseCase(this._repository);
  
  final NotificationRepository _repository;

  Future<String?> call() {
    return _repository.getFcmToken();
  }
}

/// Get current payload
class GetNotificationPayloadUseCase {
  GetNotificationPayloadUseCase(this._repository);
  
  final NotificationRepository _repository;

  NotificationPayloadEntity? call() {
    return _repository.payload;
  }
}
```

**Why?**
- Single responsibility (one use case = one operation)
- Clean API for presentation layer
- Easy to test and mock
- Encapsulates business logic

---

### Step 4: Data Layer - Models

#### NotificationPayloadModel

```dart
// lib/src/data/models/notification_model.dart

import 'package:dart_mappable/dart_mappable.dart';
import '../../domain/entities/notification_payload_entity.dart';

part 'notification_model.mapper.dart';

@MappableClass(generateMethods: GenerateMethods.decode)
class NotificationPayloadModel extends NotificationPayloadEntity
    with NotificationPayloadModelMappable {
  
  NotificationPayloadModel({
    String? type,
    String? collectionId,
    String? collectionTitle,
    String? checkOutUrl,
  }) : super(
          type: _mapStringToNotificationType(type),
          collectionId: collectionId ?? '',
          collectionTitle: collectionTitle ?? '',
          checkOutUrl: checkOutUrl ?? '',
        );

  /// Parse from Firebase JSON
  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) =>
      NotificationPayloadModelMapper.fromJson(json);

  /// Map string type to enum
  static NotificationType _mapStringToNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'collection':
        return NotificationType.collection;
      case 'cart':
        return NotificationType.cart;
      case 'home':
        return NotificationType.home;
      default:
        return NotificationType.home;
    }
  }
}
```

**Why?**
- Extends domain entity (is-a relationship)
- Handles JSON parsing from Firebase
- String → Enum conversion
- Default values for safety

---

#### NotificationModel

```dart
@MappableClass(generateMethods: GenerateMethods.decode)
class NotificationModel extends NotificationEntity
    with NotificationModelMappable {
  
  NotificationModel({
    required super.title,
    required super.body,
    required super.payload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModelMapper.fromJson(json);
  }
}
```

**Why?**
- Extends domain entity
- JSON serialization capabilities
- Data layer artifact (domain doesn't know about JSON)

---

### Step 5: Data Layer - Service Interface

```dart
// lib/src/data/services/notification/notification_service.dart

import '../../../domain/entities/notification_payload_entity.dart';
import '../../models/notification_model.dart';

abstract class NotificationService {
  /// Initialize Firebase Messaging
  Future<void> initialize();
  
  /// Get FCM token
  Future<String?> getFcmToken();
  
  /// Get current payload
  NotificationPayloadEntity? get payload;
  
  /// Stream of notifications
  Stream<NotificationModel> get onNotification;
}
```

**Why?**
- Abstraction for Firebase operations
- Can be swapped with other providers (OneSignal, etc.)
- Returns models (data layer types)

---

### Step 6: Data Layer - Service Implementation

```dart
// lib/src/data/services/notification/notification_service_impl.dart

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

  final _notificationController =
      StreamController<NotificationModel>.broadcast();

  @override
  NotificationPayloadEntity? get payload => _payload;

  @override
  Stream<NotificationModel> get onNotification =>
      _notificationController.stream;

  @override
  Future<void> initialize() async {
    // 1. Register background handler (MUST be top-level function)
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 2. Request notification permissions
    await _firebaseMessaging.requestPermission();

    // 3. Get and cache FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    _cachedToken = fcmToken;
    Log.info('FCM Token Cached: $_cachedToken');

    if (fcmToken != null) {
      Log.info('✅ FCM Token: $fcmToken');
    } else {
      Log.warning(
        '⚠️ FCM Token is null. Check Firebase configuration.',
      );
    }

    // 4. Handle FOREGROUND messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Log.info('📱 Foreground: ${message.notification?.title}');
      Log.info('📦 Data: ${message.data}');

      final notification = _parseNotification(message);
      if (notification != null) {
        _payload = notification.payload;
        _notificationController.add(notification);
      }
    });

    // 5. Handle BACKGROUND → FOREGROUND (user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Log.info('🔔 Opened from background: ${message.notification?.title}');
      Log.info('📦 Data: ${message.data}');

      final notification = _parseNotification(message);
      if (notification != null) {
        _payload = notification.payload;
        _notificationController.add(notification);
      }
    });

    // 6. Handle TERMINATED → FOREGROUND
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      Log.info('🚀 Opened from terminated state');
      Log.info('📦 Data: ${initialMessage.data}');

      final notification = _parseNotification(initialMessage);
      if (notification != null) {
        _payload = notification.payload;
        _notificationController.add(notification);
      }
    }

    // 7. Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _cachedToken = newToken;
      Log.info('🔄 FCM Token refreshed: $newToken');
      // TODO: Send updated token to backend
    });
  }

  /// Parse RemoteMessage to NotificationModel
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
      Log.error('❌ Error parsing notification: $e');
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

/// Background handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
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
```

**Key Implementation Details:**

1. **Three State Handlers:**
   - `onMessage` - Foreground
   - `onMessageOpenedApp` - Background → Foreground
   - `getInitialMessage` - Terminated → Foreground

2. **Broadcast Stream:**
   - Multiple listeners can subscribe
   - Router and UI can both listen

3. **Token Caching:**
   - Stores token in memory
   - Faster subsequent reads
   - Handles token refresh

4. **Error Handling:**
   - Try-catch in parsing
   - Returns null on error
   - Logs all errors

5. **Background Handler:**
   - Top-level function (required)
   - `@pragma('vm:entry-point')` annotation
   - Cannot access UI

---

### Step 7: Data Layer - Repository Implementation

```dart
// lib/src/data/repositories/notification_repository_impl.dart

import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_payload_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification/notification_service.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  NotificationRepositoryImpl(this._notificationService);

  final NotificationService _notificationService;

  @override
  Future<void> initializeNotification() {
    return _notificationService.initialize();
  }

  @override
  Future<String?> getFcmToken() {
    return _notificationService.getFcmToken();
  }

  @override
  Stream<NotificationEntity> get onNotification =>
      _notificationService.onNotification;

  @override
  NotificationPayloadEntity? get payload => _notificationService.payload;
}
```

**Why?**
- Implements domain repository interface
- Delegates to service (no business logic here)
- Bridges data and domain layers
- Allows easy service swapping

---

## 🔌 Dependency Injection

Using Riverpod code generation:

### Service Provider

```dart
// lib/src/core/di/parts/services.dart

part of '../dependency_injection.dart';

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationServiceImpl();
}
```

**Why `keepAlive: true`?**
- Service persists throughout app lifecycle
- Stream subscriptions remain active
- FCM listeners always running

---

### Repository Provider

```dart
// lib/src/core/di/parts/repository.dart

part of '../dependency_injection.dart';

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(
    ref.read(notificationServiceProvider),
  );
}
```

---

### Use Case Providers

```dart
// lib/src/core/di/parts/use_cases.dart

part of '../dependency_injection.dart';

@riverpod
InitializaNotificationUseCase initializaNotificationUseCase(Ref ref) {
  return InitializaNotificationUseCase(
    ref.read(notificationRepositoryProvider),
  );
}

@riverpod
GetNotificationStreamUseCase getNotificationStreamUseCase(Ref ref) {
  return GetNotificationStreamUseCase(
    ref.read(notificationRepositoryProvider),
  );
}

@riverpod
GetFcmTokenUseCase getFcmTokenUseCase(Ref ref) {
  return GetFcmTokenUseCase(
    ref.read(notificationRepositoryProvider),
  );
}

@riverpod
GetNotificationPayloadUseCase getNotificationPayloadUseCase(Ref ref) {
  return GetNotificationPayloadUseCase(
    ref.read(notificationRepositoryProvider),
  );
}
```

**Dependency Flow:**
```
Use Case → Repository → Service → Firebase
```

---

## 🚀 Integration with App

### Step 1: App Startup Initialization

```dart
// lib/src/presentation/core/application_state/startup_provider/app_startup_provider.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../firebase_options.dart';
import '../../../../core/di/dependency_injection.dart';
import '../localization_provider/localization_provider.dart';

part 'app_startup_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(sharedPreferencesProvider);
  });

  // 1. Initialize Firebase (MUST be first)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Initialize SharedPreferences
  await ref.watch(sharedPreferencesProvider.future);

  // 3. Setup localization
  await ref.read(localizationProvider.notifier).setCurrentLocal();

  // 4. Initialize notifications
  await ref.watch(initializaNotificationUseCaseProvider).call();
}
```

**Why here?**
- Firebase initialized before FCM
- Catches terminated state notifications
- Ready before UI loads

---

### Step 2: Router Integration

```dart
// lib/src/presentation/core/router/router.dart

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  // Get notification stream use case
  final notificationRouteUseCase = ref.read(
    getNotificationStreamUseCaseProvider,
  );

  // Listen to notification stream
  notificationRouteUseCase.call().listen((notificationEntity) {
    final context = _rootNavigatorKey.currentContext;
    if (context == null) return; // Context not ready

    final payload = notificationEntity.payload;
    if (payload != null) {
      Log.info(
        'Received notification: ${payload.type}, navigating...',
      );

      // Navigate based on notification type
      switch (payload.type) {
        case NotificationType.collection:
          context.go(Routes.collection);
          break;
        case NotificationType.cart:
          context.go(Routes.cart);
          break;
        default:
          context.go(Routes.home);
      }
    }
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: ref.asListenable(routerStateProvider),
    initialLocation: Routes.initial,
    redirect: (context, state) {
      // ... existing redirect logic with authentication guards

      // Check protected routes
      final protectedRoutes = [
        Routes.home,
        Routes.profile,
        Routes.cart,
      ];
      final isAccessingProtectedRoute = protectedRoutes.contains(
        state.uri.path,
      );

      if (isAccessingProtectedRoute) {
        final isLoggedIn = ref
            .read(getUserLoginStatusUseCaseProvider)
            .call();

        if (!isLoggedIn) {
          // Save intended route for after login
          ref.read(saveIntendedRouteUseCaseProvider).call(state.uri.path);
          Log.info('Not logged in, saving route: ${state.uri.path}');

          // Redirect to login
          return Routes.login;
        }
      }

      return null;
    },
    routes: [
      // ... your routes
    ],
  );
}
```

**Why in router?**
- Central navigation point
- Access to navigation context
- Respects authentication guards
- Natural integration with GoRouter

---

### Step 3: Optional - Manual Payload Access

```dart
// lib/src/presentation/core/providers/notification_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_payload_entity.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationPayload extends _$NotificationPayload {
  @override
  NotificationPayloadEntity? build() {
    return ref.read(getNotificationPayloadUseCaseProvider).call();
  }

  void refresh() {
    state = ref.read(getNotificationPayloadUseCaseProvider).call();
  }
}
```

**Usage in widgets:**
```dart
// Watch for changes
final payload = ref.watch(notificationPayloadProvider);

if (payload != null) {
  // Handle payload
}

// Manual refresh
ref.read(notificationPayloadProvider.notifier).refresh();
```

---

## 🧪 Testing the Implementation

### Test FCM Token

```dart
Future<void> testFcmToken() async {
  final token = await ref.read(getFcmTokenUseCaseProvider).call();
  print('FCM Token: $token');
}
```

### Test Notification Stream

```dart
ref.read(getNotificationStreamUseCaseProvider).call().listen((notification) {
  print('Title: ${notification.title}');
  print('Body: ${notification.body}');
  print('Type: ${notification.payload?.type}');
  print('Collection ID: ${notification.payload?.collectionId}');
});
```

### Send Test from Firebase Console

1. Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter FCM token
4. Add custom data:
   ```json
   {
     "type": "collection",
     "collectionId": "123",
     "collectionTitle": "New Arrivals",
     "checkOutUrl": "https://example.com/checkout"
   }
   ```

---

## 📊 Complete Flow Diagram

```
User Taps Notification
         ↓
Firebase Messaging
         ↓
NotificationServiceImpl
    - Parses RemoteMessage
    - Creates NotificationModel
    - Adds to Stream
         ↓
NotificationRepositoryImpl
    - Forwards stream
         ↓
GetNotificationStreamUseCase
    - Exposes to presentation
         ↓
Router (GoRouter)
    - Listens to stream
    - Extracts payload
    - Checks notification type
         ↓
Authentication Guard
    - Checks if route protected
    - Verifies user logged in
         ↓
Navigation
    - context.go(route)
    - Shows target page
```

---

## ✅ Benefits of This Architecture

1. **Testable:**
   - Mock at each layer
   - Test use cases independently
   - No Firebase in domain tests

2. **Maintainable:**
   - Clear separation of concerns
   - Easy to locate code
   - Single responsibility

3. **Scalable:**
   - Add features without modifying existing code
   - Easy to add new notification types
   - Can swap Firebase for another provider

4. **Type-Safe:**
   - Compile-time safety with enums
   - No magic strings
   - IDE autocomplete support

---

## 📚 Next Steps

- ✅ Implementation complete!
- 📍 Next: [Advanced Features & Customization](./04_advanced_features.md)
- 📍 Then: [Testing & Debugging Guide](./05_testing_guide.md)

---

## 🔗 References

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

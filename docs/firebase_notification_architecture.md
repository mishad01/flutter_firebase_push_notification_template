# Firebase Push Notification Architecture

## Overview
This document outlines the architectural decisions made for implementing Firebase Cloud Messaging (FCM) push notifications in this Flutter application following Clean Architecture principles.

## Architecture Pattern: Clean Architecture with Layered Approach

### Layer Structure

```
┌─────────────────────────────────────────────────┐
│           Presentation Layer                     │
│  (UI, Providers, State Management)              │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│            Domain Layer                          │
│  (Entities, Use Cases, Repository Interfaces)   │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│             Data Layer                           │
│  (Models, Repository Impl, Services)            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│           External Dependencies                  │
│  (Firebase Messaging, Platform APIs)            │
└─────────────────────────────────────────────────┘
```

---

## Architectural Decisions

### 1. **Domain Layer First Approach**

#### Decision
Created domain entities and repository interfaces before implementing any Firebase-specific code.

#### Rationale
- **Business Logic Independence**: Domain layer defines "what" the app needs (notifications) without caring "how" they're delivered
- **Testability**: Can mock repositories and test business logic without Firebase dependencies
- **Flexibility**: Easy to swap FCM with other push notification services (OneSignal, AWS SNS, etc.) without touching business logic
- **Clear Contracts**: Repository interface (`NotificationRepository`) defines clear contracts for notification capabilities

#### Implementation
```dart
// Domain entities define business objects
NotificationEntity - Core notification structure
NotificationPayloadEntity - Custom payload data

// Repository interface defines contracts
abstract class NotificationRepository {
  Future<void> initializeNotification();
  Future<String?> getFcmToken();
  Stream<NotificationEntity> get onNotification;
}
```

---

### 2. **Separation of Service and Repository**

#### Decision
Created two separate abstractions:
- `NotificationService` (Data Layer) - Handles Firebase-specific operations
- `NotificationRepository` (Domain Layer) - Defines business capabilities

#### Rationale
- **Single Responsibility Principle**: Service handles technical implementation (Firebase APIs), Repository handles business logic coordination
- **Dependency Inversion**: Domain doesn't depend on concrete Firebase implementation
- **Testability**: Can test repository logic separately from Firebase service
- **Flexibility**: Service can be replaced (different push provider) without changing repository interface

#### Implementation
```dart
// Service (Data Layer) - Technical details
abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  Stream<NotificationModel> get onNotification;
}

// Repository (Domain Layer) - Business capabilities
class NotificationRepositoryImpl extends NotificationRepository {
  final NotificationService _notificationService;
  // Delegates to service but can add business logic
}
```

---

### 3. **Use Case Pattern for Notification Operations**

#### Decision
Created separate use cases for each notification operation:
- `InitializaNotificationUseCase` - Initialize FCM
- `GetNotificationStreamUseCase` - Stream notifications to UI

#### Rationale
- **Single Responsibility**: Each use case has one clear purpose
- **Reusability**: Use cases can be composed and reused across features
- **Testability**: Easy to test individual operations in isolation
- **Encapsulation**: Hides repository complexity from presentation layer
- **Future Extensibility**: Easy to add business rules (e.g., filtering, analytics tracking)

#### Implementation
```dart
class InitializaNotificationUseCase {
  final NotificationRepository _repository;
  
  Future<void> call() async {
    return _repository.initializeNotification();
  }
}

class GetNotificationStreamUseCase {
  final NotificationRepository _repository;
  
  Stream<NotificationEntity> call() {
    return _repository.onNotification;
  }
}
```

---

### 4. **Stream-Based Notification Delivery**

#### Decision
Used `Stream<NotificationEntity>` to deliver notifications from service to UI layer.

#### Rationale
- **Reactive Programming**: Natural fit for asynchronous, event-driven notifications
- **Multiple Listeners**: Multiple widgets can listen to same notification stream
- **State Management Integration**: Streams work seamlessly with Riverpod and Flutter state management
- **Firebase Alignment**: FirebaseMessaging already uses streams (`onMessage`, `onMessageOpenedApp`)
- **Memory Efficient**: BroadcastStream allows multiple subscribers without duplicating data

#### Implementation
```dart
class NotificationServiceImpl {
  final _notificationController = StreamController<NotificationModel>.broadcast();
  
  Stream<NotificationModel> get onNotification => _notificationController.stream;
  
  // Listens to Firebase streams and pipes to our stream
  FirebaseMessaging.onMessage.listen((message) {
    final notification = _parseNotification(message);
    if (notification != null) {
      _notificationController.add(notification);
    }
  });
}
```

---

### 5. **Entity-Model Separation**

#### Decision
Separated domain entities from data models:
- `NotificationEntity` / `NotificationPayloadEntity` (Domain)
- `NotificationModel` / `NotificationPayloadModel` (Data)

#### Rationale
- **Clean Architecture Principle**: Domain entities remain pure, no serialization concerns
- **Framework Independence**: Entities don't depend on JSON parsing libraries (dart_mappable)
- **Flexibility**: Can change serialization strategy without affecting domain layer
- **Type Safety**: Models extend entities, ensuring type compatibility
- **Data Transformation**: Models handle JSON parsing, entities focus on business logic

#### Implementation
```dart
// Domain Entity - Pure business object
class NotificationEntity {
  final String? title;
  final String? body;
  final NotificationPayloadEntity? payload;
}

// Data Model - Handles serialization
@MappableClass()
class NotificationModel extends NotificationEntity {
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModelMapper.fromJson(json);
  }
}
```

---

### 6. **Comprehensive Firebase State Handling**

#### Decision
Implemented handlers for all three Firebase notification states:
- **Foreground** - App is open and active
- **Background** - App is running but not active
- **Terminated** - App was completely closed

#### Rationale
- **Complete User Experience**: Users get consistent behavior regardless of app state
- **Data Preservation**: `getInitialMessage()` ensures notifications aren't lost when app launches from terminated state
- **Platform Best Practices**: Follows Firebase and platform-specific notification guidelines
- **Business Requirements**: Common requirement to handle deep links and navigation from notifications in all states

#### Implementation
```dart
// Foreground
FirebaseMessaging.onMessage.listen((message) { ... });

// Background -> Foreground
FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });

// Terminated -> Foreground
final initialMessage = await _firebaseMessaging.getInitialMessage();

// Background handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async { ... }
```

---

### 7. **Dependency Injection with Riverpod**

#### Decision
Used Riverpod code generation for dependency injection with `keepAlive: true` for notification services.

#### Rationale
- **Lifecycle Management**: `keepAlive: true` ensures notification service persists throughout app lifecycle
- **Type Safety**: Code generation provides compile-time safety
- **Singleton Pattern**: Single instance of NotificationService manages all Firebase listeners
- **Testability**: Easy to override providers in tests
- **Consistency**: Matches existing DI pattern in the codebase

#### Implementation
```dart
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationServiceImpl();
}

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(ref.read(notificationServiceProvider));
}
```

---

### 8. **Error Handling and Logging**

#### Decision
Implemented comprehensive logging at the service layer with try-catch for parsing operations.

#### Rationale
- **Debugging**: Detailed logs help troubleshoot notification delivery issues
- **Graceful Degradation**: Parse errors don't crash the app
- **Production Monitoring**: Logs can be sent to crash reporting tools
- **Developer Experience**: Clear, formatted logs help during development

#### Implementation
```dart
NotificationModel? _parseNotification(RemoteMessage message) {
  try {
    final payload = message.data.isNotEmpty
        ? NotificationPayloadModel.fromJson(message.data)
        : null;
    return NotificationModel(title: ..., body: ..., payload: payload);
  } catch (e) {
    Log.error('Error parsing notification: $e');
    return null;
  }
}
```

---

### 9. **Custom Payload Structure**

#### Decision
Defined a specific payload structure for business requirements:
```dart
class NotificationPayloadEntity {
  final String type;
  final String collectionId;
  final String collectionTitle;
  final String checkOutUrl;
}
```

#### Rationale
- **Deep Linking**: Supports navigation to specific app screens
- **Business Context**: Carries domain-specific information (collections, checkout)
- **Type Safety**: Strongly typed fields prevent runtime errors
- **Extensibility**: Easy to add new fields for future features
- **Validation**: Can validate payload structure at parse time

---

### 10. **Token Caching Strategy**

#### Decision
Cached FCM token in memory (`_cachedToken`) and provided `getFcmToken()` method.

#### Rationale
- **Performance**: Avoid unnecessary async calls to Firebase
- **Backend Integration**: Token needed to send targeted notifications
- **Token Refresh**: Can implement token refresh logic in one place
- **Offline Support**: Cached token available even if Firebase is temporarily unavailable

#### Implementation
```dart
class NotificationServiceImpl {
  String? _cachedToken;
  
  Future<void> initialize() async {
    final fcmToken = await _firebaseMessaging.getToken();
    _cachedToken = fcmToken;
    Log.info('FCM Token Cached: $_cachedToken');
  }
  
  Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
```

---

## Benefits of This Architecture

### 1. **Maintainability**
- Clear separation of concerns makes code easy to understand and modify
- Changes to Firebase implementation don't affect business logic
- Each layer has well-defined responsibilities

### 2. **Testability**
- Can test business logic without Firebase dependencies
- Mock repositories and services easily
- Use cases can be tested independently

### 3. **Scalability**
- Easy to add new notification features (local notifications, scheduled notifications)
- Can integrate multiple push providers
- Stream architecture supports complex notification workflows

### 4. **Flexibility**
- Can replace FCM with other providers (OneSignal, etc.)
- Can add middleware (analytics, filtering) without changing core logic
- Easy to extend payload structure for new features

### 5. **Type Safety**
- Strongly typed entities prevent runtime errors
- Riverpod code generation provides compile-time dependency checking
- dart_mappable ensures JSON parsing safety

---

## Trade-offs and Considerations

### Complexity vs. Simplicity
- **Trade-off**: More files and abstractions than a simple implementation
- **Justification**: Complexity is managed and isolated; long-term benefits outweigh initial overhead

### Performance
- **Trade-off**: Additional abstraction layers add minimal overhead
- **Justification**: Overhead is negligible; improved testability and maintainability worth it

### Learning Curve
- **Trade-off**: Team needs to understand Clean Architecture principles
- **Justification**: Industry best practice; improves code quality and team collaboration

---

## Future Enhancements

1. **Local Notifications**: Add flutter_local_notifications for foreground display
2. **Notification History**: Store notifications in local database
3. **Analytics Integration**: Track notification open rates and engagement
4. **A/B Testing**: Support different notification strategies
5. **Rich Notifications**: Images, actions, and custom layouts
6. **Notification Preferences**: User-configurable notification settings
7. **Multi-channel Support**: Different notification types with different behaviors

---

## Conclusion

This architecture provides a robust, maintainable, and testable foundation for Firebase push notifications. By following Clean Architecture principles and separating concerns across layers, the implementation remains flexible and can evolve with changing business requirements while maintaining code quality and developer productivity.

The pattern established here can serve as a template for integrating other third-party services and features in the application.

# Firebase Push Notification Flow Diagram

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           APP INITIALIZATION                                 │
│                                                                              │
│  ┌────────────────┐                                                          │
│  │   main.dart    │                                                          │
│  └────────┬───────┘                                                          │
│           │                                                                  │
│           ▼                                                                  │
│  ┌────────────────┐         ┌─────────────────────────────────┐             │
│  │  GoRouter      │────────▶│  AppStartupWidget               │             │
│  │  (router.dart) │         │  - Shows Splash during startup  │             │
│  └────────────────┘         └──────────────┬──────────────────┘             │
│                                            │                                 │
│                                            ▼                                 │
│                             ┌──────────────────────────────┐                │
│                             │  appStartupProvider          │                │
│                             │  (app_startup_provider.dart) │                │
│                             │                              │                │
│                             │  1. Initialize Firebase      │                │
│                             │  2. Load SharedPreferences   │                │
│                             │  3. Set Localization         │                │
│                             │  4. Initialize Notification  │◀───────────┐   │
│                             └──────────────┬───────────────┘            │   │
│                                            │                            │   │
└────────────────────────────────────────────┼────────────────────────────┼───┘
                                             │                            │
                                             ▼                            │
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DEPENDENCY INJECTION (DI)                             │
│                         (dependency_injection.dart)                          │
│                                                                              │
│  Step 4: Calls initializaNotificationUseCaseProvider                        │
│          └──────────────────────────────────────────┐                       │
│                                                      │                       │
│  ┌───────────────────────────────────────────────────▼─────────────────┐    │
│  │  USE CASES (parts/use_cases.dart)                                   │    │
│  │  ┌────────────────────────────────────────────────────────────┐     │    │
│  │  │ initializaNotificationUseCaseProvider                      │     │    │
│  │  │   ├─ InitializaNotificationUseCase                         │     │    │
│  │  │   └─ Depends on: notificationRepositoryProvider ───────────┼─┐   │    │
│  │  │                                                            │ │   │    │
│  │  │ getNotificationStreamUseCaseProvider                      │ │   │    │
│  │  │   ├─ GetNotificationStreamUseCase                         │ │   │    │
│  │  │   └─ Depends on: notificationRepositoryProvider ───────────┼─┘   │    │
│  │  └────────────────────────────────────────────────────────────┘     │    │
│  └────────────────────────────────────────┬─────────────────────────────┘    │
│                                           │                                  │
│  ┌────────────────────────────────────────▼─────────────────────────────┐   │
│  │  REPOSITORIES (parts/repository.dart)                                │   │
│  │  ┌────────────────────────────────────────────────────────────┐      │   │
│  │  │ notificationRepositoryProvider (keepAlive: true)           │      │   │
│  │  │   ├─ NotificationRepositoryImpl                            │      │   │
│  │  │   └─ Depends on: notificationServiceProvider ──────────────┼──┐   │   │
│  │  └────────────────────────────────────────────────────────────┘  │   │   │
│  └──────────────────────────────────────────────────────────────────┼───┘   │
│                                                                      │       │
│  ┌──────────────────────────────────────────────────────────────────▼───┐   │
│  │  SERVICES (parts/services.dart)                                      │   │
│  │  ┌────────────────────────────────────────────────────────────┐      │   │
│  │  │ notificationServiceProvider (keepAlive: true)              │      │   │
│  │  │   └─ NotificationServiceImpl                               │      │   │
│  │  └────────────────────────────────────────────────────────────┘      │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                    LAYERED ARCHITECTURE (Clean Architecture)                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 1: DOMAIN (Business Logic)                                             │
│ Location: lib/src/domain/                                                    │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ USE CASES (notification_use_case.dart)                           │        │
│  │                                                                  │        │
│  │  ┌────────────────────────────────────────────────────┐          │        │
│  │  │ InitializaNotificationUseCase                      │          │        │
│  │  │  - call() → Future<void>                           │          │        │
│  │  │  - Initializes notification system                 │          │        │
│  │  └────────────────────────────────────────────────────┘          │        │
│  │                                                                  │        │
│  │  ┌────────────────────────────────────────────────────┐          │        │
│  │  │ GetNotificationStreamUseCase                       │          │        │
│  │  │  - call() → Stream<NotificationEntity>             │          │        │
│  │  │  - Returns notification stream                     │          │        │
│  │  └────────────────────────────────────────────────────┘          │        │
│  └──────────────────┬───────────────────────────────────────────────┘        │
│                     │ uses                                                   │
│                     ▼                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ REPOSITORY INTERFACE (notification_repository.dart)              │        │
│  │                                                                  │        │
│  │  abstract class NotificationRepository {                        │        │
│  │    Future<void> initializeNotification();                       │        │
│  │    Future<String?> getFcmToken();                               │        │
│  │    Stream<NotificationEntity> get onNotification;               │        │
│  │  }                                                               │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ ENTITIES (notification_entity.dart)                              │        │
│  │  - NotificationEntity (pure data class)                          │        │
│  │  - NotificationPayloadEntity                                     │        │
│  └──────────────────────────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────────────────────────┘
                                     ▲
                                     │ implements
                                     │
┌──────────────────────────────────────────────────────────────────────────────┐
│ LAYER 2: DATA (Implementation)                                               │
│ Location: lib/src/data/                                                      │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ REPOSITORY IMPLEMENTATION (notification_repository_impl.dart)    │        │
│  │                                                                  │        │
│  │  class NotificationRepositoryImpl implements                    │        │
│  │         NotificationRepository {                                │        │
│  │                                                                  │        │
│  │    final NotificationService _notificationService;              │        │
│  │                                                                  │        │
│  │    Future<void> initializeNotification() {                      │        │
│  │      return _notificationService.initialize();                  │        │
│  │    }                                                             │        │
│  │                                                                  │        │
│  │    Stream<NotificationEntity> get onNotification =>             │        │
│  │      _notificationService.onNotification;                       │        │
│  │  }                                                               │        │
│  └──────────────────┬───────────────────────────────────────────────┘        │
│                     │ uses                                                   │
│                     ▼                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ SERVICE INTERFACE (notification_service.dart)                    │        │
│  │                                                                  │        │
│  │  abstract class NotificationService {                           │        │
│  │    Future<void> initialize();                                   │        │
│  │    Future<String?> getFcmToken();                               │        │
│  │    Stream<NotificationModel> get onNotification;                │        │
│  │  }                                                               │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                     ▲                                        │
│                                     │ implements                             │
│                                     │                                        │
│  ┌──────────────────────────────────▼───────────────────────────────┐        │
│  │ SERVICE IMPLEMENTATION (notification_service_impl.dart)          │        │
│  │                                                                  │        │
│  │  class NotificationServiceImpl extends NotificationService {    │        │
│  │                                                                  │        │
│  │    final FirebaseMessaging _firebaseMessaging;                  │        │
│  │    final StreamController<NotificationModel> _controller;       │        │
│  │                                                                  │        │
│  │    Future<void> initialize() {                                  │        │
│  │      // Request permissions                                     │        │
│  │      // Get FCM token                                           │        │
│  │      // Listen to foreground messages                           │        │
│  │      // Listen to background messages                           │        │
│  │      // Handle notification opened from terminated state        │        │
│  │    }                                                             │        │
│  │  }                                                               │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                     │                                        │
│  ┌──────────────────────────────────▼───────────────────────────────┐        │
│  │ MODELS (notification_model.dart)                                 │        │
│  │  - NotificationModel (data transfer object)                      │        │
│  │  - NotificationPayloadModel                                      │        │
│  └──────────────────────────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ uses
                                     ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ EXTERNAL DEPENDENCY: Firebase Cloud Messaging                                │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ FirebaseMessaging (firebase_messaging package)                   │        │
│  │                                                                  │        │
│  │  - onBackgroundMessage (static handler)                         │        │
│  │  - requestPermission()                                          │        │
│  │  - getToken()                                                   │        │
│  │  - onMessage (foreground)                                       │        │
│  │  - onMessageOpenedApp (background → foreground)                 │        │
│  │  - getInitialMessage() (terminated → foreground)                │        │
│  └──────────────────────────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                    NOTIFICATION LIFECYCLE & FLOW                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────┐
│ 1. APP STARTS                                                                 │
│    └─ appStartupProvider triggers notification initialization                │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ 2. INITIALIZATION FLOW                                                        │
│                                                                               │
│    appStartupProvider                                                         │
│           │                                                                   │
│           ▼                                                                   │
│    initializaNotificationUseCaseProvider.call()                              │
│           │                                                                   │
│           ▼                                                                   │
│    NotificationRepository.initializeNotification()                           │
│           │                                                                   │
│           ▼                                                                   │
│    NotificationService.initialize()                                          │
│           │                                                                   │
│           ▼                                                                   │
│    NotificationServiceImpl performs:                                         │
│      ├─ Register background handler                                          │
│      ├─ Request notification permissions                                     │
│      ├─ Get & cache FCM token                                                │
│      ├─ Setup FirebaseMessaging.onMessage listener (foreground)              │
│      ├─ Setup FirebaseMessaging.onMessageOpenedApp listener (background)     │
│      └─ Check getInitialMessage() for terminated state                       │
│                                                                               │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│ 3. NOTIFICATION RECEIVED (3 Scenarios)                                       │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ SCENARIO A: App in FOREGROUND                                    │        │
│  │                                                                  │        │
│  │  Firebase Server sends notification                             │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  FirebaseMessaging.onMessage triggers                           │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  NotificationServiceImpl._parseNotification()                   │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  Add to _notificationController stream                          │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  Stream listeners receive NotificationModel                     │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ SCENARIO B: App in BACKGROUND                                    │        │
│  │                                                                  │        │
│  │  Firebase Server sends notification                             │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  _firebaseMessagingBackgroundHandler() called                   │        │
│  │  (logs notification details)                                    │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  User taps notification                                         │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  FirebaseMessaging.onMessageOpenedApp triggers                  │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  NotificationServiceImpl._parseNotification()                   │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  Add to _notificationController stream                          │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                                                               │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │ SCENARIO C: App TERMINATED (not running)                         │        │
│  │                                                                  │        │
│  │  Firebase Server sends notification                             │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  System shows notification in tray                              │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  User taps notification → App starts                            │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  During initialization:                                         │        │
│  │  FirebaseMessaging.getInitialMessage() returns message          │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  NotificationServiceImpl._parseNotification()                   │        │
│  │           │                                                      │        │
│  │           ▼                                                      │        │
│  │  Add to _notificationController stream                          │        │
│  └──────────────────────────────────────────────────────────────────┘        │
└───────────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW SUMMARY                                   │
└─────────────────────────────────────────────────────────────────────────────┘

Firebase Cloud Messaging
         │
         ▼
NotificationServiceImpl (receives RemoteMessage)
         │
         ▼
_parseNotification() → NotificationModel
         │
         ▼
StreamController<NotificationModel>
         │
         ▼
NotificationRepository.onNotification (Stream<NotificationEntity>)
         │
         ▼
GetNotificationStreamUseCase
         │
         ▼
Presentation Layer (Riverpod providers can listen to this stream)


┌─────────────────────────────────────────────────────────────────────────────┐
│                          KEY COMPONENTS                                      │
└─────────────────────────────────────────────────────────────────────────────┘

1. **Service Layer** (NotificationServiceImpl):
   - Wraps Firebase Messaging
   - Handles all FCM events (foreground, background, terminated)
   - Exposes Stream<NotificationModel>

2. **Repository Layer** (NotificationRepositoryImpl):
   - Abstracts the service layer
   - Converts Models to Entities (domain layer)
   - Implements domain repository interface

3. **Use Case Layer** (InitializaNotificationUseCase, GetNotificationStreamUseCase):
   - Single responsibility business logic
   - Called by presentation layer

4. **Dependency Injection** (Riverpod providers):
   - notificationServiceProvider → NotificationServiceImpl
   - notificationRepositoryProvider → NotificationRepositoryImpl
   - initializaNotificationUseCaseProvider → InitializaNotificationUseCase
   - getNotificationStreamUseCaseProvider → GetNotificationStreamUseCase

5. **App Startup**:
   - appStartupProvider orchestrates initialization
   - Called early in app lifecycle via AppStartupWidget
   - Ensures notifications are ready before app UI loads

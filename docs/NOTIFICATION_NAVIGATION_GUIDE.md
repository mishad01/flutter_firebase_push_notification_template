# Notification-Based Navigation Implementation Guide

## Current State Analysis

### Existing Notification Types
```dart
enum NotificationType { collection, home, cart }
```

### Current Notification Payload Structure
```dart
class NotificationPayloadEntity {
  final NotificationType type;
  final String collectionId;      // Used for collection type
  final String collectionTitle;   // Used for collection type
  final String checkOutUrl;       // Used for cart type
}
```

---

## Required Changes to Existing Code

### 1. Create Notification Handler Service

**File:** `lib/src/presentation/core/services/notification_handler.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/notification_payload_entity.dart';
import '../router/queued_route/queued_route_provider.dart';
import '../router/routes.dart';
import '../utils/auth_navigation_helper.dart';

class NotificationHandler {
  static void handleNotificationNavigation(
    BuildContext context,
    WidgetRef ref,
    NotificationEntity notification,
  ) {
    final payload = notification.payload;
    if (payload == null) return;

    final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();

    switch (payload.type) {
      case NotificationType.home:
        _navigateToHome(context, ref);
        break;

      case NotificationType.cart:
        _navigateToCart(context, ref, isLoggedIn);
        break;

      case NotificationType.collection:
        _navigateToCollection(
          context,
          ref,
          isLoggedIn,
          payload.collectionId,
          payload.collectionTitle,
        );
        break;
    }
  }

  static void _navigateToHome(BuildContext context, WidgetRef ref) {
    context.pushNamed(Routes.home);
  }

  static void _navigateToCart(
    BuildContext context,
    WidgetRef ref,
    bool isLoggedIn,
  ) {
    if (isLoggedIn) {
      context.pushNamed(Routes.cart);
    } else {
      // Queue cart route and redirect to login
      ref.read(queuedRouteProvider.notifier).setQueuedRoute(Routes.cart);
      context.pushNamed(Routes.login);
    }
  }

  static void _navigateToCollection(
    BuildContext context,
    WidgetRef ref,
    bool isLoggedIn,
    String collectionId,
    String collectionTitle,
  ) {
    if (collectionId.isEmpty) return;

    // Option 1: If collections don't require login
    context.pushNamed(
      Routes.collection,
      pathParameters: {'id': collectionId},
      queryParameters: {'title': collectionTitle},
    );

    // Option 2: If collections require login
    // if (isLoggedIn) {
    //   context.pushNamed(
    //     Routes.collection,
    //     pathParameters: {'id': collectionId},
    //   );
    // } else {
    //   ref.read(queuedRouteProvider.notifier).setQueuedRoute(Routes.collection);
    //   context.pushNamed(Routes.login);
    // }
  }
}
```

---

### 2. Create Notification Listener Provider

**File:** `lib/src/presentation/core/providers/notification_listener_provider.dart` (NEW)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_entity.dart';

part 'notification_listener_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<NotificationEntity> notificationListener(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.onNotification;
}
```

---

### 3. Update Main App to Listen for Notifications

**File:** `lib/main.dart` (MODIFY)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/gen/l10n/app_localizations.dart';
import 'src/core/logger/riverpod_log.dart';
import 'src/presentation/core/application_state/localization_provider/localization_provider.dart';
import 'src/presentation/core/providers/notification_listener_provider.dart';  // ADD
import 'src/presentation/core/router/router.dart';
import 'src/presentation/core/services/notification_handler.dart';  // ADD
import 'src/presentation/core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(observers: [RiverpodObserver()], child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {  // CHANGE from ConsumerWidget
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Listen to notifications
    ref.listenManual(
      notificationListenerProvider,
      (_, notification) {
        if (notification.hasValue && notification.value != null) {
          final context = ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
          if (context != null && mounted) {
            NotificationHandler.handleNotificationNavigation(
              context,
              ref,
              notification.value!,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: ref.watch(localizationProvider),
        theme: context.lightTheme,
        darkTheme: context.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: ref.read(goRouterProvider),
      ),
    );
  }
}
```

---

### 4. Add Collection Route to Routes

**File:** `lib/src/presentation/core/router/routes.dart` (MODIFY)

```dart
class Routes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String resetPassword = 'reset-password';
  static const String emailVerification = 'email-verification';
  static const String createNewPassword = 'create-new-password';
  static const String resetPasswordSuccess = 'reset-password-success';
  static const String registration = 'registration';

  static const String home = '/home';
  static const String profile = '/profile';
  static const String cart = '/cart';
  static const String collection = '/collection/:id';  // ADD
}
```

---

### 5. Add Routes to Router Configuration

**File:** `lib/src/presentation/core/router/parts/shell_routes.dart` (MODIFY)

```dart
part of '../router.dart';

StatefulShellRoute _shellRoutes(Ref ref) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return NavigationShell(statefulNavigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.home,
            name: Routes.home,
            pageBuilder: (context, state) {
              return const MaterialPage(child: HomePage());
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.profile,
            name: Routes.profile,
            pageBuilder: (context, state) {
              return const MaterialPage(child: ProfilePage());
            },
          ),
        ],
      ),
      // ADD CART ROUTE
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.cart,
            name: Routes.cart,
            pageBuilder: (context, state) {
              return const MaterialPage(child: CartPage());
            },
          ),
        ],
      ),
      // ADD COLLECTION ROUTE
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.collection,
            name: Routes.collection,
            pageBuilder: (context, state) {
              final collectionId = state.pathParameters['id'] ?? '';
              final collectionTitle = state.uri.queryParameters['title'] ?? '';
              return MaterialPage(
                child: CollectionPage(
                  collectionId: collectionId,
                  collectionTitle: collectionTitle,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
}
```

---

## Server-Side Requirements

### Firebase Cloud Messaging (FCM) Payload Structure

The server needs to send notifications with the following JSON structure:

#### 1. For **HOME** Type Notifications

```json
{
  "notification": {
    "title": "Welcome Back!",
    "body": "Check out what's new on our home page"
  },
  "data": {
    "type": "home"
  }
}
```

**Required Fields:**
- `data.type`: "home"

---

#### 2. For **CART** Type Notifications

```json
{
  "notification": {
    "title": "Items in Your Cart",
    "body": "You have 3 items waiting in your cart"
  },
  "data": {
    "type": "cart",
    "checkOutUrl": "https://yourapp.com/checkout/session123"
  }
}
```

**Required Fields:**
- `data.type`: "cart"
- `data.checkOutUrl`: String (URL for checkout, can be empty string if not needed)

**Optional Fields:**
- `data.collectionId`: "" (can be empty)
- `data.collectionTitle`: "" (can be empty)

---

#### 3. For **COLLECTION** Type Notifications

```json
{
  "notification": {
    "title": "New Collection Available!",
    "body": "Check out our Summer Collection 2024"
  },
  "data": {
    "type": "collection",
    "collectionId": "summer-2024",
    "collectionTitle": "Summer Collection 2024",
    "checkOutUrl": ""
  }
}
```

**Required Fields:**
- `data.type`: "collection"
- `data.collectionId`: String (unique identifier for the collection)
- `data.collectionTitle`: String (display name for the collection)

**Optional Fields:**
- `data.checkOutUrl`: "" (can be empty for collection type)

---

### Complete Server Payload Template

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "Notification Title",
    "body": "Notification Body"
  },
  "data": {
    "type": "home|cart|collection",
    "collectionId": "",
    "collectionTitle": "",
    "checkOutUrl": ""
  },
  "priority": "high",
  "content_available": true
}
```

---

### Server Implementation Examples

#### Node.js (Firebase Admin SDK)

```javascript
const admin = require('firebase-admin');

// Home notification
async function sendHomeNotification(deviceToken) {
  const message = {
    token: deviceToken,
    notification: {
      title: 'Welcome Back!',
      body: 'Check out what\'s new'
    },
    data: {
      type: 'home'
    },
    android: {
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-priority': '10'
      }
    }
  };
  
  await admin.messaging().send(message);
}

// Cart notification
async function sendCartNotification(deviceToken, checkoutUrl) {
  const message = {
    token: deviceToken,
    notification: {
      title: 'Items in Your Cart',
      body: 'You have items waiting'
    },
    data: {
      type: 'cart',
      checkOutUrl: checkoutUrl,
      collectionId: '',
      collectionTitle: ''
    },
    android: {
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-priority': '10'
      }
    }
  };
  
  await admin.messaging().send(message);
}

// Collection notification
async function sendCollectionNotification(deviceToken, collectionId, collectionTitle) {
  const message = {
    token: deviceToken,
    notification: {
      title: 'New Collection!',
      body: collectionTitle
    },
    data: {
      type: 'collection',
      collectionId: collectionId,
      collectionTitle: collectionTitle,
      checkOutUrl: ''
    },
    android: {
      priority: 'high'
    },
    apns: {
      headers: {
        'apns-priority': '10'
      }
    }
  };
  
  await admin.messaging().send(message);
}
```

#### Python (Firebase Admin SDK)

```python
from firebase_admin import messaging

def send_home_notification(device_token):
    message = messaging.Message(
        notification=messaging.Notification(
            title='Welcome Back!',
            body='Check out what\'s new'
        ),
        data={
            'type': 'home'
        },
        token=device_token,
        android=messaging.AndroidConfig(
            priority='high'
        ),
        apns=messaging.APNSConfig(
            headers={'apns-priority': '10'}
        )
    )
    messaging.send(message)

def send_cart_notification(device_token, checkout_url):
    message = messaging.Message(
        notification=messaging.Notification(
            title='Items in Your Cart',
            body='You have items waiting'
        ),
        data={
            'type': 'cart',
            'checkOutUrl': checkout_url,
            'collectionId': '',
            'collectionTitle': ''
        },
        token=device_token,
        android=messaging.AndroidConfig(
            priority='high'
        ),
        apns=messaging.APNSConfig(
            headers={'apns-priority': '10'}
        )
    )
    messaging.send(message)

def send_collection_notification(device_token, collection_id, collection_title):
    message = messaging.Message(
        notification=messaging.Notification(
            title='New Collection!',
            body=collection_title
        ),
        data={
            'type': 'collection',
            'collectionId': collection_id,
            'collectionTitle': collection_title,
            'checkOutUrl': ''
        },
        token=device_token,
        android=messaging.AndroidConfig(
            priority='high'
        ),
        apns=messaging.APNSConfig(
            headers={'apns-priority': '10'}
        )
    )
    messaging.send(message)
```

---

## Summary of Changes

### New Files to Create:
1. ✅ `notification_handler.dart` - Handles navigation based on notification type
2. ✅ `notification_listener_provider.dart` - Provider for notification stream
3. ⚠️ `cart_page.dart` - Cart UI page (if not exists)
4. ⚠️ `collection_page.dart` - Collection UI page (if not exists)

### Files to Modify:
1. ✅ `main.dart` - Add notification listener
2. ✅ `routes.dart` - Add collection and cart routes
3. ✅ `shell_routes.dart` - Add route configurations

### Server Requirements:
1. ✅ Send notification type in `data.type` field
2. ✅ Include relevant fields based on notification type
3. ✅ Ensure all fields are strings in the JSON payload
4. ✅ Set high priority for immediate delivery

---

## Testing Checklist

- [ ] Test HOME notification when app is foreground
- [ ] Test HOME notification when app is background
- [ ] Test HOME notification when app is terminated
- [ ] Test CART notification when logged in
- [ ] Test CART notification when logged out (should queue and redirect to login)
- [ ] Test COLLECTION notification with valid collection ID
- [ ] Test COLLECTION notification when logged out (if auth required)
- [ ] Verify queued route navigates to correct page after login
- [ ] Test with missing/invalid notification data

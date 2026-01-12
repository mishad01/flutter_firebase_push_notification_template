# Notification-Based Navigation - Implementation Summary

## ✅ What Has Been Implemented

### 1. Core Navigation Infrastructure

#### Files Created:
- ✅ **`notification_handler.dart`** - Central handler for all notification navigation logic
  - Handles HOME, CART, and COLLECTION notification types
  - Automatically checks login status
  - Queues routes for logged-out users
  - Location: `lib/src/presentation/core/services/`

- ✅ **`notification_listener_provider.dart`** - Riverpod provider for notification stream
  - Provides stream of incoming notifications
  - Auto-generated `.g.dart` file included
  - Location: `lib/src/presentation/core/providers/`

#### Files Updated:
- ✅ **`routes.dart`** - Added collection route constant
  - Added: `static const String collection = '/collection/:id';`

---

## 📋 What Still Needs to Be Done

### 1. Update Main App (Critical)

**File:** `lib/main.dart`

**Changes needed:**
```dart
// 1. Add imports
import 'src/presentation/core/providers/notification_listener_provider.dart';
import 'src/presentation/core/services/notification_handler.dart';

// 2. Change MyApp from ConsumerWidget to ConsumerStatefulWidget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

// 3. Add State class with notification listener
class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    
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
    // existing build code...
  }
}
```

---

### 2. Create Cart Page

**File:** `lib/src/presentation/features/cart/view/cart_page.dart` (NEW)

```dart
import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Center(
        child: Text('Cart Page - Implementation needed'),
      ),
    );
  }
}
```

---

### 3. Create Collection Page

**File:** `lib/src/presentation/features/collection/view/collection_page.dart` (NEW)

```dart
import 'package:flutter/material.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  final String collectionId;
  final String collectionTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collectionTitle.isEmpty ? 'Collection' : collectionTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Collection ID: $collectionId'),
            Text('Title: $collectionTitle'),
            const SizedBox(height: 20),
            const Text('Collection Page - Implementation needed'),
          ],
        ),
      ),
    );
  }
}
```

---

### 4. Update Router Configuration

**File:** `lib/src/presentation/core/router/parts/shell_routes.dart`

**Add imports:**
```dart
import '../../features/cart/view/cart_page.dart';
import '../../features/collection/view/collection_page.dart';
```

**Add routes to shell branches:**
```dart
// Add Cart Branch
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

// Add Collection Branch
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
```

---

## 🔧 Server Requirements

### Firebase Cloud Messaging Payload Format

#### For HOME notifications:
```json
{
  "notification": {
    "title": "Welcome Back!",
    "body": "Check out what's new"
  },
  "data": {
    "type": "home"
  }
}
```

#### For CART notifications:
```json
{
  "notification": {
    "title": "Items in Your Cart",
    "body": "You have items waiting"
  },
  "data": {
    "type": "cart",
    "checkOutUrl": "https://yourapp.com/checkout/session123",
    "collectionId": "",
    "collectionTitle": ""
  }
}
```

#### For COLLECTION notifications:
```json
{
  "notification": {
    "title": "New Collection!",
    "body": "Summer Collection 2024"
  },
  "data": {
    "type": "collection",
    "collectionId": "summer-2024",
    "collectionTitle": "Summer Collection 2024",
    "checkOutUrl": ""
  }
}
```

### Key Requirements:
1. **`type`** field must be: "home", "cart", or "collection"
2. All data fields should be **strings**
3. Empty fields should be **empty strings ""**, not null
4. Set **priority to high** for immediate delivery

---

## 📊 Navigation Flow

### When User is Logged In:
```
Notification Received
    ↓
NotificationHandler checks type
    ↓
Navigate directly to target page
```

### When User is Logged Out (Cart/Protected Routes):
```
Cart Notification Received
    ↓
NotificationHandler checks login status
    ↓
Route queued in QueuedRouteProvider
    ↓
User redirected to Login
    ↓
User logs in successfully
    ↓
LoginPage checks for queued route
    ↓
Navigate to Cart (queued route)
```

---

## 🧪 Testing Checklist

### Foreground Notifications:
- [ ] HOME notification when app is open
- [ ] CART notification when logged in
- [ ] CART notification when logged out
- [ ] COLLECTION notification with valid ID

### Background Notifications:
- [ ] HOME notification when app is in background
- [ ] CART notification when logged in
- [ ] CART notification when logged out
- [ ] COLLECTION notification with valid ID

### Terminated State:
- [ ] HOME notification when app is closed
- [ ] CART notification when logged in
- [ ] CART notification when logged out
- [ ] COLLECTION notification with valid ID

### Edge Cases:
- [ ] Invalid notification type
- [ ] Missing collection ID
- [ ] Empty notification data
- [ ] Multiple rapid notifications
- [ ] User logs out while cart route is queued

---

## 📂 File Structure

```
lib/src/
├── presentation/
│   ├── core/
│   │   ├── providers/
│   │   │   ├── notification_listener_provider.dart ✅
│   │   │   └── notification_listener_provider.g.dart ✅
│   │   ├── router/
│   │   │   ├── queued_route/
│   │   │   │   ├── queued_route_provider.dart ✅
│   │   │   │   └── queued_route_provider.g.dart ✅
│   │   │   ├── routes.dart ✅ (Updated)
│   │   │   └── parts/
│   │   │       └── shell_routes.dart ⚠️ (Needs update)
│   │   ├── services/
│   │   │   └── notification_handler.dart ✅
│   │   └── utils/
│   │       └── auth_navigation_helper.dart ✅
│   └── features/
│       ├── cart/
│       │   └── view/
│       │       └── cart_page.dart ⚠️ (Needs creation)
│       └── collection/
│           └── view/
│               └── collection_page.dart ⚠️ (Needs creation)
└── main.dart ⚠️ (Needs update)
```

---

## 🎯 Next Steps (In Order)

1. **Update `main.dart`** - Add notification listener (5 min)
2. **Create `cart_page.dart`** - Basic cart UI (10 min)
3. **Create `collection_page.dart`** - Basic collection UI (10 min)
4. **Update `shell_routes.dart`** - Add route configurations (5 min)
5. **Test with FCM** - Send test notifications from Firebase Console (15 min)
6. **Implement actual cart/collection logic** - Based on business requirements

---

## 📖 Additional Resources

- Full implementation guide: `docs/NOTIFICATION_NAVIGATION_GUIDE.md`
- Queued route system docs: `docs/QUEUED_ROUTE_SYSTEM.md`
- Server payload examples included in the guide

---

## ⚡ Quick Start

To complete the implementation quickly:

1. Copy the code from this document for each "⚠️ Needs update/creation" file
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Test each notification type
4. Refine based on your specific requirements

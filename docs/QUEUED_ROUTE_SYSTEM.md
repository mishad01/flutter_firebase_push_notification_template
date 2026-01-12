# Queued Route System

The queued route system allows you to store a route when a user is logged out and automatically navigate to it after successful login.

## How It Works

1. **When User Is Logged Out**: 
   - User tries to access a protected route (e.g., cart)
   - System stores the route in `QueuedRouteProvider`
   - User is redirected to login page

2. **After Successful Login**:
   - Login page checks for queued route
   - If exists, navigates to queued route
   - Otherwise, navigates to home page
   - Queued route is cleared after consumption

## Usage Examples

### Example 1: Navigate to Cart (Recommended)

Use the `AuthNavigationHelper` for common scenarios:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/auth_navigation_helper.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Automatically checks login status and queues route if needed
        AuthNavigationHelper.navigateToCart(context, ref);
      },
      child: Text('Go to Cart'),
    );
  }
}
```

### Example 2: Navigate to Any Protected Route

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/auth_navigation_helper.dart';
import '../core/router/routes.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Works with any route
        AuthNavigationHelper.navigateWithAuth(
          context,
          ref,
          Routes.profile,
        );
      },
      child: Text('Go to Profile'),
    );
  }
}
```

### Example 3: Manual Control

For more control, use the provider directly:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/queued_route/queued_route_provider.dart';
import '../core/router/routes.dart';
import '../../../core/di/dependency_injection.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();
        
        if (!isLoggedIn) {
          // Queue the route
          ref.read(queuedRouteProvider.notifier).setQueuedRoute(Routes.cart);
          // Navigate to login
          context.pushNamed(Routes.login);
        } else {
          // User is logged in, navigate directly
          context.pushNamed(Routes.cart);
        }
      },
      child: Text('Go to Cart'),
    );
  }
}
```

### Example 4: Handling Notification Deep Links

When receiving a notification for cart while logged out:

```dart
void handleNotification(NotificationPayloadEntity payload, BuildContext context, WidgetRef ref) {
  switch (payload.type) {
    case NotificationType.cart:
      // Check if user is logged in
      final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();
      
      if (!isLoggedIn) {
        // Queue cart route and redirect to login
        ref.read(queuedRouteProvider.notifier).setQueuedRoute(Routes.cart);
        context.pushNamed(Routes.login);
      } else {
        // User is logged in, navigate directly to cart
        context.pushNamed(Routes.cart);
      }
      break;
    
    case NotificationType.home:
      context.pushNamed(Routes.home);
      break;
    
    case NotificationType.collection:
      // Handle collection navigation
      break;
  }
}
```

## Provider Methods

### `setQueuedRoute(String route)`
Stores a route to navigate to after login.

### `consumeQueuedRoute()`
Returns the queued route and clears it. Returns `null` if no route is queued.

### `clearQueuedRoute()`
Manually clears the queued route without returning it.

## Implementation Details

The system is implemented in three parts:

1. **`QueuedRouteProvider`** (`lib/src/presentation/core/router/queued_route/queued_route_provider.dart`)
   - Stores the queued route in memory
   - Provides methods to set, consume, and clear queued routes

2. **`LoginPage`** (Updated)
   - Checks for queued route after successful login
   - Navigates to queued route or home page
   - Automatically consumes the queued route

3. **`AuthNavigationHelper`** (`lib/src/presentation/core/utils/auth_navigation_helper.dart`)
   - Provides convenient methods for protected navigation
   - Checks login status automatically
   - Handles route queueing and redirection

## Notes

- The queued route is stored in memory only (not persisted)Based on the type of notification what changes do you need to make to existing code and what do you need from the server to navigate user to appropriate page.
- Only one route can be queued at a time
- The queued route is automatically cleared after consumption
- If user logs in through a different flow, the queued route is still preserved

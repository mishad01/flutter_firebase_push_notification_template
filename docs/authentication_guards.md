# Authentication Guards & Notification-Based Deep Linking

## Overview

This document explains how the authentication guard system works in the Flutter app, specifically for handling deep links from push notifications to protected routes based on notification types.

## Problem Solved

When a user receives a push notification and taps it, the app should navigate to different pages based on the notification type:

- **Collection notifications**: Navigate to collection page (PUBLIC - no authentication required)
- **Cart notifications**: Navigate to cart page (PROTECTED - requires authentication)  
- **Home notifications**: Navigate to home page (PROTECTED - requires authentication)

For protected routes, if the user is not logged in:
1. Redirect to login page first
2. Save the intended destination
3. After successful login, redirect to the originally intended page

## Notification Types & Routing

### Notification Payload Structure

```dart
enum NotificationType {
  collection,  // Public route - no auth required
  cart,        // Protected route - auth required
  home,        // Protected route - auth required
}

class NotificationPayloadEntity {
  final NotificationType type;
  final String collectionId;
  final String collectionTitle;
  final String checkOutUrl;
}
```

### Route Protection Matrix

| Notification Type | Route | Protected | Auth Required |
|------------------|-------|-----------|---------------|
| `collection` | `/collection` | ❌ No | ❌ No |
| `cart` | `/cart` | ✅ Yes | ✅ Yes |
| `home` | `/home` | ✅ Yes | ✅ Yes |

## Implementation

### 1. Enhanced Router Repository

Added methods to handle intended routes:

```dart
abstract class RouterRepository {
  // Existing methods...
  
  // New methods for intended routes
  void saveIntendedRoute(String route);
  String? getIntendedRoute();
  void clearIntendedRoute();
}
```

### 2. Cache Service Enhancement

Added a new cache key for storing intended routes:

```dart
enum CacheKey {
  // Existing keys...
  intendedRoute,
}
```

### 3. Router Authentication Guard

Updated the GoRouter redirect logic to implement authentication guards:

```dart
redirect: (context, state) {
  // Handle protected routes
  final protectedRoutes = [Routes.home, Routes.profile, Routes.cart];
  final isAccessingProtectedRoute = protectedRoutes.contains(state.uri.path);
  
  if (isAccessingProtectedRoute) {
    final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();
    
    if (!isLoggedIn) {
      // Save intended route and redirect to login
      ref.read(saveIntendedRouteUseCaseProvider).call(state.uri.path);
      return Routes.login;
    }
  }
  
  return null;
},
```

### 4. Notification Navigation Service

Created a dedicated service to handle notification-based routing:

```dart
class NotificationNavigationService {
  void handleNotificationNavigation(
    GoRouter router,
    NotificationPayloadEntity payload,
  ) {
    String targetRoute;

    switch (payload.type) {
      case NotificationType.collection:
        targetRoute = Routes.collection; // Public route
        break;
      case NotificationType.cart:
        targetRoute = Routes.cart; // Protected route
        break;
      case NotificationType.home:
        targetRoute = Routes.home; // Protected route
        break;
    }

    // Router guard handles auth check automatically
    router.go(targetRoute);
  }
}
```

### 4. Login Flow Enhancement

Modified the login success handler to redirect to intended route:

```dart
ref.listenManual(loginProvider, (previous, next) {
  switch (next) {
    case AsyncData(:final value) when value != null:
      // Check for intended route
      final intendedRoute = ref.read(getIntendedRouteUseCaseProvider).call();
      if (intendedRoute != null) {
        // Clear and redirect to intended route
        ref.read(clearIntendedRouteUseCaseProvider).call();
        context.go(intendedRoute);
      } else {
        // Default redirect to home
        context.pushReplacementNamed(Routes.home);
      }
  }
});
```

### 5. Session Management

Updated authentication repository to:
- Always save login status when user logs in successfully
- Clear intended route when user logs out

## How It Works

### Scenario 1: Collection Notification (Public Route)
1. User taps collection notification
2. App navigates directly to `/collection` page
3. ✅ No authentication required - user sees collection immediately

### Scenario 2: Cart Notification (Protected Route - User Logged In)
1. User taps cart notification
2. Router checks authentication status
3. ✅ User is logged in - navigates directly to `/cart`

### Scenario 3: Cart Notification (Protected Route - User NOT Logged In)
1. User taps cart notification  
2. Router checks authentication status
3. ❌ User not logged in:
   - Saves `/cart` as intended route
   - Redirects to `/login`
4. User enters credentials and logs in
5. Login success handler:
   - Retrieves intended route (`/cart`)
   - Clears cached intended route
   - Redirects user to `/cart`

### Scenario 4: Home Notification (Protected Route)
1. User taps home notification
2. Same flow as cart notification above
3. If not logged in → login → redirect to home
4. If logged in → direct navigation to home

## Testing the Implementation

### Test Case 1: Collection Notification (Public Route)
1. Logout if currently logged in (optional)
2. Tap "Collection Notification (PUBLIC)" button
3. ✅ Should navigate directly to collection page (no login required)

### Test Case 2: Cart Notification - Not Logged In
1. **Make sure you're logged out**
2. Tap "Cart Notification (PROTECTED)" button  
3. Should redirect to login page
4. Log in with valid credentials
5. ✅ Should redirect to cart page after successful login

### Test Case 3: Cart Notification - Already Logged In
1. **Make sure you're logged in**
2. Tap "Cart Notification (PROTECTED)" button
3. ✅ Should go directly to cart page

### Test Case 4: Normal Login Flow
1. Navigate to login page normally
2. Log in with valid credentials  
3. ✅ Should redirect to home page (default route)

## UI Elements Added

### Home Page
- Enhanced with notification testing buttons:
  - **Collection Notification (PUBLIC)** - Tests public route navigation
  - **Cart Notification (PROTECTED)** - Tests protected route with auth guard
  - **Profile Navigation** - Navigate to profile page
- Visual feedback with snackbars for each notification type
- Better organized layout with cards and sections

### Collection Page (NEW)
- **Public route** - accessible without authentication
- Shows purple collection icon and messaging
- Demonstrates that some routes don't require authentication

### Cart Page (NEW)  
- **Protected route** - requires authentication
- Shows orange shopping cart icon and messaging
- Success message when accessed after authentication
- Mock cart items display

### Profile Page
- Enhanced to show it's a protected route
- Added success message when accessed after authentication
- Better visual design with icons and messages

## Protected Routes Configuration

The authentication guard system supports both protected and public routes:

```dart
// Protected routes requiring authentication
final protectedRoutes = [
  Routes.home,     // '/home' 
  Routes.profile,  // '/profile'
  Routes.cart,     // '/cart' 
];

// Public routes (no authentication required)
final publicRoutes = [
  Routes.collection, // '/collection'
  Routes.login,      // '/login'
  Routes.registration, // '/registration'
  // ... other auth-related routes
];
```

### Adding New Routes

**To add a protected route:**
```dart
final protectedRoutes = [
  Routes.home, 
  Routes.profile, 
  Routes.cart,
  Routes.orders,    // ← Add new protected route
  Routes.settings,  // ← Add new protected route
];
```

**To add a public route:**
Just add the route normally - it won't be checked by the auth guard.

### Notification Type Mapping

Update the notification service to handle new route types:

```dart
switch (payload.type) {
  case NotificationType.collection:
    targetRoute = Routes.collection; // Public
    break;
  case NotificationType.cart:
    targetRoute = Routes.cart; // Protected
    break;
  case NotificationType.orders:   // ← New type
    targetRoute = Routes.orders;   // Protected
    break;
  case NotificationType.home:
    targetRoute = Routes.home; // Protected
    break;
}
```

## Error Handling

The system handles several edge cases:
- Invalid intended routes are ignored
- Logout clears all authentication state including intended routes
- Multiple login attempts don't create route conflicts
- Deep links to non-existent routes are handled by normal routing

## Security Considerations

1. **No Sensitive Data**: Intended routes only store path information, no sensitive data
2. **Session-Based**: Intended routes are cleared on logout for security
3. **Validation**: Only valid application routes are stored as intended destinations
4. **Automatic Cleanup**: Intended routes are automatically cleared after use

## Future Enhancements

Potential improvements to consider:

1. **Route Parameters**: Support for storing route parameters with intended routes
2. **Expiry**: Add expiry time for intended routes
3. **Multiple Routes**: Support for route history/stack
4. **Permissions**: Route-level permission checks
5. **Analytics**: Track authentication guard effectiveness

## Usage Examples

### From Notification Service (Firebase Cloud Messaging)
```dart
// When handling push notification tap
void handleNotificationTap(Map<String, dynamic> data) {
  final notificationService = ref.read(notificationNavigationServiceProvider);
  final router = ref.read(goRouterProvider);
  
  // Extract notification type from FCM data
  final type = data['type']; // 'collection', 'cart', 'home'
  final collectionId = data['collectionId'];
  
  notificationService.handleNotificationTap(
    router,
    type,
    collectionId: collectionId,
  );
}
```

### From Deep Link Handling
```dart
// When handling app deep links
void handleDeepLink(Uri uri) {
  // Extract route information
  final path = uri.path;
  
  // This will trigger auth guard if route is protected
  navigatorKey.currentContext?.go(path);
}
```

### From In-App Navigation
```dart
// Direct navigation to any route
void navigateBasedOnNotification(NotificationType type) {
  switch (type) {
    case NotificationType.collection:
      context.go(Routes.collection); // No auth needed
      break;
    case NotificationType.cart:
      context.go(Routes.cart); // Auth guard will handle if needed
      break;
    case NotificationType.home:
      context.go(Routes.home); // Auth guard will handle if needed
      break;
  }
}
```

### Testing Buttons (From Home Page)
```dart
// Simulate collection notification (public)
FilledButton.icon(
  onPressed: () => context.go(Routes.collection),
  icon: const Icon(Icons.collections),
  label: const Text('Collection Notification (PUBLIC)'),
)

// Simulate cart notification (protected)
FilledButton.icon(
  onPressed: () => context.go(Routes.cart),
  icon: const Icon(Icons.shopping_cart), 
  label: const Text('Cart Notification (PROTECTED)'),
)
```

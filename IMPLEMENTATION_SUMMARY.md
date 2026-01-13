# Queued Router Implementation Summary

## What Was Implemented

A complete queued router system for handling push notification navigation with authentication checks. The system intelligently routes users based on notification types while respecting authentication requirements.

## Files Created and Modified

### 1. Domain Layer

#### Modified `lib/src/domain/entities/notification_payload_entity.dart`
- Enhanced existing `NotificationType` enum with:
  - String values for each type (`cart`, `collection`, `home`, `announcement`)
  - `requiresAuthentication` property to determine which routes need login
  - Helper method `fromString()` to convert notification payload strings

#### `lib/src/domain/use_cases/handle_notification_navigation_use_case.dart`
- Core business logic for processing notifications
- Determines target route based on notification type
- Decides whether to navigate immediately or queue the route
- Returns `QueuedRouter?` (null means route was queued)

### 2. Data Layer

#### Updated `lib/src/data/repositories/router_repository_impl.dart`
- Added `saveQueuedRoute()` - Saves route to cache as JSON
- Added `getQueuedRoute()` - Retrieves and deserializes queued route
- Added `clearQueuedRoute()` - Removes queued route from cache

#### Updated `lib/src/data/services/cache/cache_service.dart`
- Added `queuedRoute` to `CacheKey` enum

### 3. Presentation Layer

#### `lib/src/presentation/features/cart/view/cart_page.dart`
- Cart page that displays when user clicks cart notification
- Accepts `checkOutUrl` parameter

#### `lib/src/presentation/features/collection/view/collection_page.dart`
- Collection page that displays when user clicks collection notification
- Accepts `collectionId` and `collectionTitle` parameters

#### `lib/src/presentation/core/providers/notification_navigation_provider.dart`
- Provider that listens to notification stream
- Handles navigation logic using `HandleNotificationNavigationUseCase`
- Provides `processQueuedRoute()` method to execute queued routes after login

#### Updated `lib/src/presentation/features/authentication/login/view/login_page.dart`
- Added call to `processQueuedRoute()` after successful login
- Ensures queued routes are executed when user logs in

### 4. Router Configuration

#### Updated `lib/src/presentation/core/router/routes.dart`
- Added `cart` and `collection` route constants

#### Updated `lib/src/presentation/core/router/router.dart`
- Added cart and collection page imports

#### Updated `lib/src/presentation/core/router/parts/shell_routes.dart`
- Added `_protectedRoutes()` function with cart and collection routes
- Routes accept query parameters for dynamic data

#### Updated `lib/src/presentation/core/router/router_state/router_state_provider.dart`
- Added `getAndClearQueuedRoute()` method

### 5. Dependency Injection

#### Updated `lib/src/core/di/dependency_injection.dart`
- Added import for `HandleNotificationNavigationUseCase`

#### Updated `lib/src/core/di/parts/use_cases.dart`
- Added providers for:
  - `SaveQueuedRouteUseCase`
  - `GetQueuedRouteUseCase`
  - `ClearQueuedRouteUseCase`
  - `HandleNotificationNavigationUseCase`

#### Updated `lib/src/domain/repositories/router_repository.dart`
- Added method signatures for queued route management

#### Updated `lib/src/domain/use_cases/router_use_case.dart`
- Added use case classes for queue management

### 6. Documentation

#### `docs/QUEUED_ROUTER.md`
- Comprehensive documentation explaining the system
- Usage examples
- Flow diagrams in text
- Integration points

#### `lib/src/presentation/core/providers/notification_handler_example.dart`
- Code examples showing how to use the system
- Sample notification payloads

## How It Works

### Scenario 1: User is Logged In
1. Notification arrives with type "collection"
2. `HandleNotificationNavigationUseCase` checks authentication
3. User is logged in → Returns route immediately
4. `NotificationNavigationProvider` navigates to collection page

### Scenario 2: User is NOT Logged In
1. Notification arrives with type "cart"
2. `HandleNotificationNavigationUseCase` checks authentication
3. User is NOT logged in → Saves route to cache, returns null
4. User sees login page
5. After successful login, `processQueuedRoute()` is called
6. Queued route is retrieved and user navigates to cart page

### Scenario 3: Public Route (Announcement)
1. Notification arrives with type "announcement"
2. `HandleNotificationNavigationUseCase` sees no authentication required
3. Returns home route immediately
4. User navigates to home page (regardless of login state)

## Key Features

✅ **Authentication-aware routing** - Routes requiring auth are queued when user is not logged in
✅ **Automatic queue processing** - Queued routes execute automatically after successful login
✅ **Type-safe navigation** - Uses enums and entities for type safety
✅ **Persistent queuing** - Routes saved in cache survive app restarts
✅ **Flexible route data** - Supports query params, path params, and extra data
✅ **Clean architecture** - Properly separated concerns across domain, data, and presentation layers

## Usage

### In Your Notification Handler
```dart
final payload = NotificationPayloadEntity(
  type: 'cart',
  collectionId: '',
  collectionTitle: '',
  checkOutUrl: 'https://example.com/checkout',
);

final navigationUseCase = ref.read(handleNotificationNavigationUseCaseProvider);
final route = navigationUseCase.call(payload);
// If route is null, it was queued for after login
```

### Adding New Routes
1. Add type to `NotificationType` enum
2. Update `requiresAuthentication` getter if needed
3. Add case in `HandleNotificationNavigationUseCase`
4. Create page widget
5. Add route in router configuration

## Testing Recommendations

1. Test notification with logged in user
2. Test notification with logged out user
3. Test queue persistence across app restarts
4. Test multiple queued routes (should only process the most recent)
5. Test public routes (should never queue)

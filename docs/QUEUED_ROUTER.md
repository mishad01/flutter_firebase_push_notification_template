# Queued Router System

## Overview
The queued router system handles navigation based on push notification payloads with authentication checks. It ensures users are properly authenticated before navigating to protected routes, queuing navigation requests when necessary.

## How It Works

### Notification Types
The system supports four notification types defined in the `NotificationType` enum (located in `notification_payload_entity.dart`):

1. **cart** - Requires authentication, navigates to cart page
2. **collection** - Requires authentication, navigates to collection page  
3. **home** - No authentication required, navigates to home page
4. **announcement** - No authentication required, navigates to home page

### Navigation Flow

#### For Authenticated Routes (cart, collection)
- **If user is logged in**: Navigate immediately to the specified route
- **If user is not logged in**: 
  1. Queue the route for later
  2. User sees login page
  3. After successful login, queued route is processed and user is navigated to the intended destination

#### For Public Routes (home, announcement)
- Always navigate immediately, no authentication check required

### Key Components

#### 1. NotificationType Enum
```dart
enum NotificationType {
  cart, collection, home, announcement
}
```

#### 2. QueuedRouter Entity
Stores route information including:
- Route name
- Path parameters
- Query parameters
- Extra data

#### 3. HandleNotificationNavigationUseCase
Processes notification payloads and determines:
- Target route based on notification type
- Whether to navigate immediately or queue the route

#### 4. NotificationNavigationProvider
Listens to notification stream and handles navigation logic

#### 5. RouterRepository
Manages queued routes in cache:
- `saveQueuedRoute()` - Saves route for later
- `getQueuedRoute()` - Retrieves queued route
- `clearQueuedRoute()` - Clears queued route after processing

### Usage Example

When a notification arrives with payload:
```json
{
  "type": "collection",
  "collectionId": "123",
  "collectionTitle": "Summer Sale",
  "checkOutUrl": ""
}
```

**Scenario 1: User is logged in**
- User is immediately navigated to: `/collection?collectionId=123&collectionTitle=Summer%20Sale`

**Scenario 2: User is not logged in**
- Route is queued in cache
- User is shown login page
- After successful login, user is automatically navigated to the collection page

### Routes

- `/cart` - Cart page (requires authentication)
- `/collection` - Collection page (requires authentication)
- `/home` - Home page (public)

### Integration Points

1. **Login Page** - After successful login, calls `processQueuedRoute()` to navigate to any queued destination
2. **Notification Handler** - Listens to notifications and triggers appropriate navigation
3. **Router State** - Manages overall routing state and queued routes

## Adding New Protected Routes

To add a new route that requires authentication:

1. Add the notification type to `NotificationType` enum
2. Update `requiresAuthentication` getter if needed
3. Add route case in `HandleNotificationNavigationUseCase`
4. Create the page widget
5. Add route definition in router configuration

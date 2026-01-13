# Quick Start Guide - Queued Router

## Usage in Your App

### Step 1: Initialize Notification Listener (Already Done)

The `NotificationNavigationProvider` automatically listens to notifications when the app starts.

### Step 2: Send Notifications with Proper Payload

#### Example Payloads:

**Cart Notification (requires authentication):**
```json
{
  "type": "cart",
  "collectionId": "",
  "collectionTitle": "",
  "checkOutUrl": "https://example.com/checkout/abc123"
}
```

**Collection Notification (requires authentication):**
```json
{
  "type": "collection",
  "collectionId": "summer-2024",
  "collectionTitle": "Summer Collection 2024",
  "checkOutUrl": ""
}
```

**Home Notification (public):**
```json
{
  "type": "home",
  "collectionId": "",
  "collectionTitle": "",
  "checkOutUrl": ""
}
```

**Announcement Notification (public):**
```json
{
  "type": "announcement",
  "collectionId": "",
  "collectionTitle": "",
  "checkOutUrl": ""
}
```

## Expected Behavior

### If User is Logged In:
- **Cart** → Navigates to `/cart?checkOutUrl=...`
- **Collection** → Navigates to `/collection?collectionId=...&collectionTitle=...`
- **Home/Announcement** → Navigates to `/home`

### If User is NOT Logged In:
- **Cart** → Route queued, shows login, then navigates after login
- **Collection** → Route queued, shows login, then navigates after login
- **Home/Announcement** → Immediately navigates to `/home` (no login required)

## Testing

### Test Case 1: Logged In User + Cart Notification
```dart
// User is logged in
// Send notification with type="cart"
// Expected: Immediately navigate to cart page with checkout URL
```

### Test Case 2: Logged Out User + Collection Notification
```dart
// User is NOT logged in
// Send notification with type="collection"
// Expected: 
//   1. Route queued in cache
//   2. User sees login page
//   3. User logs in
//   4. Automatically navigate to collection page
```

### Test Case 3: Logged Out User + Announcement
```dart
// User is NOT logged in
// Send notification with type="announcement"
// Expected: Immediately navigate to home page (no login needed)
```

## Adding Custom Routes

To add a new protected route (e.g., "orders"):

1. Add to enum in `notification_payload_entity.dart`:
```dart
enum NotificationType {
  cart('cart'),
  collection('collection'),
  home('home'),
  announcement('announcement'),
  orders('orders'); // New type
  
  // ...
  
  bool get requiresAuthentication {
    return this == NotificationType.cart || 
           this == NotificationType.collection ||
           this == NotificationType.orders; // Add here if requires auth
  }
}
```

2. Add route in `routes.dart`:
```dart
static const String orders = '/orders';
```

3. Add case in `handle_notification_navigation_use_case.dart`:
```dart
case NotificationType.orders:
  route = QueuedRouter(
    name: '/orders',
    queryParams: {'orderId': payload.orderId}, // Add needed params
  );
  break;
```

4. Create the page and add to router configuration.

## Troubleshooting

### Route not navigating after login?
- Check that `processQueuedRoute()` is called in `login_page.dart` after successful login
- Verify the route is saved in cache (check using cache service)

### Navigation happens before login?
- Verify the route is in the `requiresAuthentication` getter
- Check the login status is correctly returned by `isUserLoggedIn()`

### Queue not persisting across app restarts?
- Verify SharedPreferences is properly initialized
- Check cache service is correctly saving/retrieving JSON

## Architecture

```
Notification → HandleNotificationNavigationUseCase
                         ↓
              Check Authentication
                         ↓
                    ┌────┴────┐
                    │         │
                Logged In  Not Logged In
                    │         │
                    │         ↓
                    │    Queue Route
                    │         │
                    │    Show Login
                    │         │
                    │    Login Success
                    │         │
                    │    Process Queue
                    │         │
                    └────┬────┘
                         ↓
                    Navigate
```

## Support

For more details:
- See `docs/QUEUED_ROUTER.md` for comprehensive documentation
- See `IMPLEMENTATION_SUMMARY.md` for implementation details
- See `notification_handler_example.dart` for code examples

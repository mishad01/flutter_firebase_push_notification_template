import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_payload_entity.dart';

/// Example: How to use the queued router system with notifications
/// 
/// This provider shows how to handle incoming notifications and trigger
/// the appropriate navigation based on the notification payload.
class NotificationHandlerExample extends ConsumerWidget {
  const NotificationHandlerExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Example 1: Listen to notification stream
    ref.listen(getNotificationStreamUseCaseProvider, (previous, next) {
      final stream = next.call();
      stream.listen((notification) {
        final payload = notification.payload;
        if (payload != null) {
          _handleNotification(ref, payload);
        }
      });
    });

    return const Scaffold(
      body: Center(
        child: Text('Notification Handler Example'),
      ),
    );
  }

  void _handleNotification(WidgetRef ref, NotificationPayloadEntity payload) {
    // Use the HandleNotificationNavigationUseCase to process the notification
    final navigationUseCase = ref.read(handleNotificationNavigationUseCaseProvider);
    final route = navigationUseCase.call(payload);

    if (route != null) {
      // Navigation happens immediately (user is logged in or route is public)
      debugPrint('Navigating to: ${route.name}');
      // Navigation will be handled by NotificationNavigationProvider
    } else {
      // Route was queued (user needs to login first)
      debugPrint('Route queued for after login');
      // User will see login page and navigate after successful login
    }
  }
}

/// Example notification payloads:

// 1. Cart notification (requires authentication)
// {
//   "type": "cart",
//   "collectionId": "",
//   "collectionTitle": "",
//   "checkOutUrl": "https://example.com/checkout/abc123"
// }

// 2. Collection notification (requires authentication)
// {
//   "type": "collection",
//   "collectionId": "summer-2024",
//   "collectionTitle": "Summer Collection",
//   "checkOutUrl": ""
// }

// 3. Home notification (no authentication required)
// {
//   "type": "home",
//   "collectionId": "",
//   "collectionTitle": "",
//   "checkOutUrl": ""
// }

// 4. Announcement notification (no authentication required)
// {
//   "type": "announcement",
//   "collectionId": "",
//   "collectionTitle": "",
//   "checkOutUrl": ""
// }

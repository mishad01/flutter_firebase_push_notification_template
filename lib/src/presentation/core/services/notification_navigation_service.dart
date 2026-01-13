import 'package:go_router/go_router.dart';

import '../../../domain/entities/notification_payload_entity.dart';
import '../router/routes.dart';

class NotificationNavigationService {
  NotificationNavigationService();

  /// Handles navigation based on notification payload
  ///
  /// This method will navigate to the appropriate route based on the notification type:
  /// - collection: Goes to collection page (public, no auth required)
  /// - cart: Goes to cart page (protected, requires auth)
  /// - home: Goes to home page (protected, requires auth)
  ///
  /// If user is not authenticated and tries to access protected routes,
  /// the router's authentication guard will handle the redirection to login.
  void handleNotificationNavigation(
    GoRouter router,
    NotificationPayloadEntity payload,
  ) {
    String targetRoute;

    switch (payload.type) {
      case NotificationType.collection:
        targetRoute = Routes.collection;
        break;
      case NotificationType.cart:
        targetRoute = Routes.cart;
        break;
      case NotificationType.home:
        targetRoute = Routes.home;
        break;
    }

    // Navigate to the target route
    // If the route is protected and user is not authenticated,
    // the router guard will automatically handle login redirection
    router.go(targetRoute);
  }

  /// Convenience method to handle notification tap from push notification
  void handleNotificationTap(
    GoRouter router,
    String? notificationType, {
    String? collectionId,
    String? collectionTitle,
    String? checkOutUrl,
  }) {
    // Create payload from notification data
    final payload = NotificationPayloadEntity(
      type: _mapStringToNotificationType(notificationType),
      collectionId: collectionId ?? '',
      collectionTitle: collectionTitle ?? '',
      checkOutUrl: checkOutUrl ?? '',
    );

    handleNotificationNavigation(router, payload);
  }

  NotificationType _mapStringToNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'collection':
        return NotificationType.collection;
      case 'cart':
        return NotificationType.cart;
      case 'home':
        return NotificationType.home;
      default:
        return NotificationType.home;
    }
  }
}

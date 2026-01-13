import '../entities/notification_payload_entity.dart';
import '../entities/queued_router.dart';
import '../repositories/router_repository.dart';

final class HandleNotificationNavigationUseCase {
  HandleNotificationNavigationUseCase(this.repository);

  final RouterRepository repository;

  QueuedRouter? call(NotificationPayloadEntity payload) {
    final notificationType = payload.type;
    
    // Check if user is logged in
    final isLoggedIn = repository.isUserLoggedIn();

    // Determine the route based on notification type
    QueuedRouter? route;
    
    switch (notificationType) {
      case NotificationType.cart:
        route = QueuedRouter(
          name: '/cart',
          queryParams: {'checkOutUrl': payload.checkOutUrl},
        );
        break;
      case NotificationType.collection:
        route = QueuedRouter(
          name: '/collection',
          queryParams: {
            'collectionId': payload.collectionId,
            'collectionTitle': payload.collectionTitle,
          },
        );
        break;
      case NotificationType.announcement:
      case NotificationType.home:
        route = QueuedRouter(name: '/home');
        break;
    }

    // If route requires authentication and user is not logged in, queue it
    if (notificationType.requiresAuthentication && !isLoggedIn) {
      repository.saveQueuedRoute(route);
      return null; // Return null to indicate navigation should wait
    }

    // Otherwise, return the route for immediate navigation
    return route;
  }
}

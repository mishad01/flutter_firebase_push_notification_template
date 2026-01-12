import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/entities/notification_payload_entity.dart';
import '../router/queued_route/queued_route_provider.dart';
import '../router/routes.dart';

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

    context.pushNamed(
      Routes.collection,
      pathParameters: {'id': collectionId},
      queryParameters: {'title': collectionTitle},
    );
  }
}

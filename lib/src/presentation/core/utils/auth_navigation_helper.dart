import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/dependency_injection.dart';
import '../router/queued_route/queued_route_provider.dart';
import '../router/routes.dart';

/// Helper class to handle navigation that requires authentication
class AuthNavigationHelper {
  /// Navigate to cart. If user is not logged in, queue the route and redirect to login
  static void navigateToCart(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();
    
    if (isLoggedIn) {
      context.pushNamed(Routes.cart);
    } else {
      // Queue the cart route for after login
      ref.read(queuedRouteProvider.notifier).setQueuedRoute(Routes.cart);
      // Navigate to login
      context.pushNamed(Routes.login);
    }
  }

  /// Navigate to any route. If user is not logged in, queue the route and redirect to login
  static void navigateWithAuth(
    BuildContext context,
    WidgetRef ref,
    String route,
  ) {
    final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();
    
    if (isLoggedIn) {
      context.pushNamed(route);
    } else {
      // Queue the route for after login
      ref.read(queuedRouteProvider.notifier).setQueuedRoute(route);
      // Navigate to login
      context.pushNamed(Routes.login);
    }
  }
}

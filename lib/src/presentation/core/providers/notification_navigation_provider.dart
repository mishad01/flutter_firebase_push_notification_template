import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/queued_router.dart';
import '../router/router.dart';
import '../router/router_state/router_state_provider.dart';

part 'notification_navigation_provider.g.dart';

@riverpod
class NotificationNavigation extends _$NotificationNavigation {
  @override
  void build() {
    // Listen to notification stream
    ref.listen(getNotificationStreamUseCaseProvider, (previous, next) {
      next.call().listen((notification) {
        final payload = notification.payload;
        if (payload != null) {
          _handleNotificationNavigation(payload);
        }
      });
    });
  }

  void _handleNotificationNavigation(dynamic payload) {
    final navigationUseCase =
        ref.read(handleNotificationNavigationUseCaseProvider);
    final route = navigationUseCase.call(payload);

    if (route != null) {
      // Navigate immediately
      _navigateToRoute(route);
    }
    // If route is null, it means it's queued for after login
  }

  void _navigateToRoute(QueuedRouter route) {
    final router = ref.read(goRouterProvider);
    router.goNamed(
      route.name,
      pathParameters: route.pathParams ?? {},
      queryParameters: route.queryParams ?? {},
      extra: route.extra,
    );
  }

  void processQueuedRoute() {
    final routerState = ref.read(routerStateProvider.notifier);
    final queuedRoute = routerState.getAndClearQueuedRoute();
    
    if (queuedRoute != null) {
      _navigateToRoute(queuedRoute);
    }
  }
}

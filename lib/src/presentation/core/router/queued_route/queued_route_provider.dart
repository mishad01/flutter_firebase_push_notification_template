import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'queued_route_provider.g.dart';

@Riverpod(keepAlive: true)
class QueuedRoute extends _$QueuedRoute {
  @override
  String? build() {
    return null;
  }

  void setQueuedRoute(String route) {
    state = route;
  }

  String? consumeQueuedRoute() {
    final route = state;
    state = null;
    return route;
  }

  void clearQueuedRoute() {
    state = null;
  }
}

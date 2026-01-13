import '../entities/queued_router.dart';

abstract class RouterRepository {
  bool isOnboardingCompleted();

  bool isUserLoggedIn();

  void saveOnboardingAsCompleted();

  void saveQueuedRoute(QueuedRouter route);

  QueuedRouter? getQueuedRoute();

  void clearQueuedRoute();
}

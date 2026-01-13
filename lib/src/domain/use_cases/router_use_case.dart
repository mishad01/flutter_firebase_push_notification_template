import '../entities/queued_router.dart';
import '../repositories/router_repository.dart';

final class GetOnboardingStatusUseCase {
  GetOnboardingStatusUseCase(this.repository);

  final RouterRepository repository;

  bool call() {
    return repository.isOnboardingCompleted();
  }
}

final class GetUserLoginStatusUseCase {
  GetUserLoginStatusUseCase(this.repository);

  final RouterRepository repository;

  bool call() {
    return repository.isUserLoggedIn();
  }
}

final class MarkOnboardingCompletedUseCase {
  MarkOnboardingCompletedUseCase(this.repository);

  final RouterRepository repository;

  void call() {
    repository.saveOnboardingAsCompleted();
  }
}
final class IsUserLoggedInUseCase {
  IsUserLoggedInUseCase(this.repository);

  final RouterRepository repository;

  bool call() {
    return repository.isUserLoggedIn();
  }
}

final class SaveQueuedRouteUseCase {
  SaveQueuedRouteUseCase(this.repository);

  final RouterRepository repository;

  void call(QueuedRouter route) {
    repository.saveQueuedRoute(route);
  }
}

final class GetQueuedRouteUseCase {
  GetQueuedRouteUseCase(this.repository);

  final RouterRepository repository;

  QueuedRouter? call() {
    return repository.getQueuedRoute();
  }
}

final class ClearQueuedRouteUseCase {
  ClearQueuedRouteUseCase(this.repository);

  final RouterRepository repository;

  void call() {
    repository.clearQueuedRoute();
  }
}


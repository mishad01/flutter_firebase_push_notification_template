import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class InitializaNotificationUseCase {
  InitializaNotificationUseCase(this._repository);
  NotificationRepository _repository;

  Future<void> call() async {
    return _repository.initializeNotification();
  }
}

class GetNotificationStreamUseCase {
  GetNotificationStreamUseCase(this._repository);
  final NotificationRepository _repository;

  Stream<NotificationEntity> call() {
    return _repository.onNotification;
  }
}

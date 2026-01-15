import '../entities/notification_entity.dart';
import '../entities/notification_payload_entity.dart';
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

class GetFcmTokenUseCase {
  GetFcmTokenUseCase(this._repository);
  final NotificationRepository _repository;

  Future<String?> call() {
    return _repository.getFcmToken();
  }
}

class GetNotificationPayloadUseCase {
  GetNotificationPayloadUseCase(this._repository);
  final NotificationRepository _repository;

  NotificationPayloadEntity? call() {
    return _repository.payload;
  }
}

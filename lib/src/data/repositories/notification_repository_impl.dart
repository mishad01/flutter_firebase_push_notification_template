import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification/notification_service.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  NotificationRepositoryImpl(this._notificationService);

  final NotificationService _notificationService;

  @override
  Future<void> initializeNotification() {
    return _notificationService.initialize();
  }

  @override
  Future<String?> getFcmToken() {
    return _notificationService.getFcmToken();
  }

  @override
  Stream<NotificationEntity> get onNotification =>
      _notificationService.onNotification;
}

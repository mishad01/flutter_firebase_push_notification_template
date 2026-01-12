import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<void> initializeNotification();
  Future<String?> getFcmToken();
  Stream<NotificationEntity> get onNotification;
}

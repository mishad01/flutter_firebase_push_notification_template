import '../entities/notification_entity.dart';
import '../entities/notification_payload_entity.dart';

abstract class NotificationRepository {
  Future<void> initializeNotification();
  Future<String?> getFcmToken();
  NotificationPayloadEntity? get payload;
  Stream<NotificationEntity> get onNotification;
}

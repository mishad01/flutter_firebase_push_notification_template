import '../../../domain/entities/notification_payload_entity.dart';
import '../../models/notification_model.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getFcmToken();
  NotificationPayloadEntity? get payload;
  Stream<NotificationModel> get onNotification;
}

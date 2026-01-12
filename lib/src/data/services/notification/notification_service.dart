import '../../models/notification_model.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<String?> getFcmToken();
  Stream<NotificationModel> get onNotification;
}

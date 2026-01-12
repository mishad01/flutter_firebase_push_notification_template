import 'notification_payload_entity.dart';

class NotificationEntity {
  NotificationEntity({this.title, this.body, this.payload});

  final String? title;
  final String? body;
  final NotificationPayloadEntity? payload;
}

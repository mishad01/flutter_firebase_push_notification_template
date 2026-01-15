enum NotificationType { collection, cart, home }

class NotificationPayloadEntity {
  NotificationPayloadEntity({
    required this.type,
    required this.collectionId,
    required this.collectionTitle,
    required this.checkOutUrl,
  });
  final NotificationType type;
  final String collectionId;
  final String collectionTitle;
  final String checkOutUrl;
}

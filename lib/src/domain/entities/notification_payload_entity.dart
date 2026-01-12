class NotificationPayloadEntity {
  NotificationPayloadEntity({
    required this.type,
    required this.collectionId,
    required this.collectionTitle,
    required this.checkOutUrl,
  });
  final String type;
  final String collectionId;
  final String collectionTitle;
  final String checkOutUrl;
}

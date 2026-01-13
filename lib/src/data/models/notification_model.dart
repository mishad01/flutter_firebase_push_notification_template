import 'package:dart_mappable/dart_mappable.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_payload_entity.dart';

part 'notification_model.mapper.dart';

@MappableClass(generateMethods: GenerateMethods.decode)
class NotificationModel extends NotificationEntity
    with NotificationModelMappable {
  NotificationModel({
    required super.title,
    required super.body,
    required super.payload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModelMapper.fromJson(json);
  }
}

@MappableClass(generateMethods: GenerateMethods.decode)
class NotificationPayloadModel extends NotificationPayloadEntity
    with NotificationPayloadModelMappable {
  NotificationPayloadModel({
    required super.type,
    required super.collectionId,
    required super.collectionTitle,
    required super.checkOutUrl,
  });

  static NotificationType _mapStringToNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'cart':
        return NotificationType.cart;
      case 'collection':
        return NotificationType.collection;
      case 'home':
        return NotificationType.home;
      default:
        return NotificationType.home;
    }
  }

  @MappableField(key: 'type')
  static NotificationType get typeFromString => NotificationType.home;

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) {
    return NotificationPayloadModel(
      type: _mapStringToNotificationType(json['type'] as String?),
      collectionId: json['collectionId'] as String,
      collectionTitle: json['collectionTitle'] as String,
      checkOutUrl: json['checkOutUrl'] as String,
    );
  }
}

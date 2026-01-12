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

class NotificationPayloadModel extends NotificationPayloadEntity {
  NotificationPayloadModel({
    required super.type,
    required super.collectionId,
    required super.collectionTitle,
    required super.checkOutUrl,
  });

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) {
    // Parse the type field manually from string to enum
    NotificationType type = NotificationType.collection;
    if (json['type'] is String) {
      final typeString = (json['type'] as String).toLowerCase();
      switch (typeString) {
        case 'collection':
          type = NotificationType.collection;
          break;
        case 'home':
          type = NotificationType.home;
          break;
        case 'cart':
          type = NotificationType.cart;
          break;
        default:
          // Default to collection if unknown type
          type = NotificationType.collection;
      }
    }

    return NotificationPayloadModel(
      type: type,
      collectionId: json['collectionId'] as String? ?? '',
      collectionTitle: json['collectionTitle'] as String? ?? '',
      checkOutUrl: json['checkOutUrl'] as String? ?? '',
    );
  }
}

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

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) {
    return NotificationPayloadModelMapper.fromJson(json);
  }
}

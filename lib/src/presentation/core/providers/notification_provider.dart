import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_payload_entity.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationPayload extends _$NotificationPayload {
  @override
  NotificationPayloadEntity? build() {
    return ref.read(getNotificationPayloadUseCaseProvider).call();
  }

  void refresh() {
    state = ref.read(getNotificationPayloadUseCaseProvider).call();
  }
}

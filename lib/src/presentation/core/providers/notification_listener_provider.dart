import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../domain/entities/notification_entity.dart';

part 'notification_listener_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<NotificationEntity> notificationListener(Ref ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.onNotification;
}

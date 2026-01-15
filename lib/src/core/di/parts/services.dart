part of '../dependency_injection.dart';

@Riverpod(keepAlive: true)
CacheService cacheService(Ref ref) {
  return SharedPreferencesService(
    ref.read(sharedPreferencesProvider).requireValue,
  );
}

@riverpod
RestClient restClientService(Ref ref) {
  return RestClient(ref.read(dioProvider));
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationServiceImpl();
}

@Riverpod(keepAlive: true)
NotificationNavigationService notificationNavigationService(Ref ref) {
  return NotificationNavigationService();
}

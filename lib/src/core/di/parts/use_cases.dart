part of '../dependency_injection.dart';

@riverpod
LoginUseCase loginUseCase(Ref ref) {
  return LoginUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
LogoutUseCase logoutUseCase(Ref ref) {
  return LogoutUseCase(ref.read(authenticationRepositoryProvider));
}

@riverpod
GetCurrentLocaleUseCase getCurrentLocaleUseCase(Ref ref) {
  return GetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}

@riverpod
SetCurrentLocaleUseCase setCurrentLocaleUseCase(Ref ref) {
  return SetCurrentLocaleUseCase(ref.read(localeRepositoryProvider));
}

@riverpod
ResetRepositoryUseCase resetRepositoryUseCase(Ref ref) {
  return const ResetRepositoryUseCase();
}

@riverpod
GetOnboardingStatusUseCase getOnboardingStatusUseCase(Ref ref) {
  return GetOnboardingStatusUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
GetUserLoginStatusUseCase getUserLoginStatusUseCase(Ref ref) {
  return GetUserLoginStatusUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
MarkOnboardingCompletedUseCase markOnboardingCompletedUseCase(Ref ref) {
  return MarkOnboardingCompletedUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
SaveIntendedRouteUseCase saveIntendedRouteUseCase(Ref ref) {
  return SaveIntendedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
GetIntendedRouteUseCase getIntendedRouteUseCase(Ref ref) {
  return GetIntendedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
ClearIntendedRouteUseCase clearIntendedRouteUseCase(Ref ref) {
  return ClearIntendedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
InitializaNotificationUseCase initializaNotificationUseCase(Ref ref) {
  return InitializaNotificationUseCase(
    ref.read(notificationRepositoryProvider),
  );
}

@riverpod
GetNotificationStreamUseCase getNotificationStreamUseCase(Ref ref) {
  return GetNotificationStreamUseCase(ref.read(notificationRepositoryProvider));
}

@riverpod
IsAuthenticatedUseCase isAuthenticatedUseCase(Ref ref) {
  return IsAuthenticatedUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
GetFcmTokenUseCase getFcmTokenUseCase(Ref ref) {
  return GetFcmTokenUseCase(ref.read(notificationRepositoryProvider));
}

@riverpod
GetNotificationPayloadUseCase getNotificationPayloadUseCase(Ref ref) {
  return GetNotificationPayloadUseCase(
    ref.read(notificationRepositoryProvider),
  );
}

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
IsUserLoggedInUseCase isUserLoggedInUseCase(Ref ref) {
  return IsUserLoggedInUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
SaveQueuedRouteUseCase saveQueuedRouteUseCase(Ref ref) {
  return SaveQueuedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
GetQueuedRouteUseCase getQueuedRouteUseCase(Ref ref) {
  return GetQueuedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
ClearQueuedRouteUseCase clearQueuedRouteUseCase(Ref ref) {
  return ClearQueuedRouteUseCase(ref.read(routerRepositoryProvider));
}

@riverpod
HandleNotificationNavigationUseCase handleNotificationNavigationUseCase(Ref ref) {
  return HandleNotificationNavigationUseCase(ref.read(routerRepositoryProvider));
}

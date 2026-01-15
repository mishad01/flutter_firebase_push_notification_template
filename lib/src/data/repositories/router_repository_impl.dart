import '../../domain/repositories/router_repository.dart';
import '../services/cache/cache_service.dart';

class RouterRepositoryImpl extends RouterRepository {
  RouterRepositoryImpl({required this.cacheService});

  final CacheService cacheService;

  @override
  bool isOnboardingCompleted() {
    return cacheService.get(CacheKey.isOnBoardingCompleted) ?? false;
  }

  @override
  bool isUserLoggedIn() {
    return cacheService.get(CacheKey.isLoggedIn) ?? false;
  }

  @override
  void saveOnboardingAsCompleted() {
    cacheService.save(CacheKey.isOnBoardingCompleted, true);
  }

  @override
  void saveIntendedRoute(String route) {
    cacheService.save(CacheKey.intendedRoute, route);
  }

  @override
  String? getIntendedRoute() {
    return cacheService.get<String>(CacheKey.intendedRoute);
  }

  @override
  void clearIntendedRoute() {
    cacheService.remove([CacheKey.intendedRoute]);
  }
}

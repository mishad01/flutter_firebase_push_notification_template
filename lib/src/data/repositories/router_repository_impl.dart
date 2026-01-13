import 'dart:convert';

import '../../domain/entities/queued_router.dart';
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
  void saveQueuedRoute(QueuedRouter route) {
    final routeJson = jsonEncode({
      'name': route.name,
      'extra': route.extra,
      'pathParams': route.pathParams,
      'queryParams': route.queryParams,
    });
    cacheService.save(CacheKey.queuedRoute, routeJson);
  }

  @override
  QueuedRouter? getQueuedRoute() {
    final routeJson = cacheService.get<String>(CacheKey.queuedRoute);
    if (routeJson == null) return null;

    try {
      final json = jsonDecode(routeJson) as Map<String, dynamic>;
      return QueuedRouter(
        name: json['name'] as String,
        extra: json['extra'],
        pathParams: json['pathParams'] != null
            ? Map<String, String>.from(json['pathParams'] as Map)
            : null,
        queryParams: json['queryParams'] != null
            ? Map<String, dynamic>.from(json['queryParams'] as Map)
            : null,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  void clearQueuedRoute() {
    cacheService.remove([CacheKey.queuedRoute]);
  }
 
}

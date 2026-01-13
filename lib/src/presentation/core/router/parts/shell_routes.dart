part of '../router.dart';

StatefulShellRoute _shellRoutes(Ref ref) {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return NavigationShell(statefulNavigationShell: navigationShell);
    },
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.home,
            name: Routes.home,
            pageBuilder: (context, state) {
              return const MaterialPage(child: HomePage());
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.profile,
            name: Routes.profile,
            pageBuilder: (context, state) {
              return const MaterialPage(child: ProfilePage());
            },
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _protectedRoutes(Ref ref) {
  return [
    GoRoute(
      path: Routes.cart,
      name: Routes.cart,
      pageBuilder: (context, state) {
        final checkOutUrl = state.uri.queryParameters['checkOutUrl'];
        return MaterialPage(child: CartPage(checkOutUrl: checkOutUrl));
      },
    ),
    GoRoute(
      path: Routes.collection,
      name: Routes.collection,
      pageBuilder: (context, state) {
        final collectionId = state.uri.queryParameters['collectionId'];
        final collectionTitle = state.uri.queryParameters['collectionTitle'];
        return MaterialPage(
          child: CollectionPage(
            collectionId: collectionId,
            collectionTitle: collectionTitle,
          ),
        );
      },
    ),
  ];
}

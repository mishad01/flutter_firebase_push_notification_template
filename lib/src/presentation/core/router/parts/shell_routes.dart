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
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.collection,
            name: Routes.collection,
            pageBuilder: (context, state) {
              return const MaterialPage(child: CollectionPage());
            },
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.cart,
            name: Routes.cart,
            pageBuilder: (context, state) {
              return const MaterialPage(child: CartPage());
            },
          ),
        ],
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/di/dependency_injection.dart';
import '../../../core/extensions/riverpod_extensions.dart';
import '../../../core/logger/log.dart';
import '../../features/authentication/forgot_password/view/create_new_password_page.dart';
import '../../features/authentication/forgot_password/view/email_verification_page.dart';
import '../../features/authentication/forgot_password/view/reset_password_page.dart';
import '../../features/authentication/forgot_password/view/reset_password_success_page.dart';
import '../../features/authentication/login/view/login_page.dart';
import '../../features/authentication/registration/view/registration_page.dart';
import '../../features/cart/view/cart_page.dart';
import '../../features/collection/view/collection_page.dart';
import '../../features/home/view/home_page.dart';
import '../../features/onboarding/view/onboarding_page.dart';
import '../../features/profile/view/profile_page.dart';
import '../../features/splash/view/splash_page.dart';
import '../widgets/app_startup/startup_widget.dart';
import '../widgets/navigation_shell.dart';
import 'router_state/router_state_provider.dart';
import 'routes.dart';

part 'parts/authentication_routes.dart';
part 'parts/on_boarding_routes.dart';
part 'parts/shell_routes.dart';
part 'router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Root');

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: ref.asListenable(routerStateProvider),
    initialLocation: Routes.initial,
    redirect: (context, state) {
      Log.info('Redirecting to ${state.uri}');

      // Handle initial, onboarding, and splash routes
      if ([
        Routes.initial,
        Routes.onboarding,
        Routes.splash,
      ].contains(state.uri.path)) {
        return ref.asListenable(routerStateProvider).value;
      }

      // Check if user is trying to access protected routes
      final protectedRoutes = [Routes.home, Routes.profile, Routes.cart];
      final isAccessingProtectedRoute = protectedRoutes.contains(
        state.uri.path,
      );

      if (isAccessingProtectedRoute) {
        final isLoggedIn = ref.read(getUserLoginStatusUseCaseProvider).call();

        if (!isLoggedIn) {
          // Save the intended route for later redirection
          ref.read(saveIntendedRouteUseCaseProvider).call(state.uri.path);
          Log.info(
            'User not logged in, saving intended route: ${state.uri.path}',
          );

          // Redirect to login
          return Routes.login;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.initial,
        name: Routes.initial,
        pageBuilder: (context, state) {
          return const NoTransitionPage(
            child: AppStartupWidget(
              loading: SplashPage(),
              loaded: SplashPage(),
            ),
          );
        },
      ),
      ..._onboardingRoutes(ref),
      ..._authenticationRoutes(ref),
      _shellRoutes(ref),
    ],
  );
}

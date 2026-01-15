import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/app_localization.dart';
import '../../../core/application_state/logout_provider/logout_provider.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(logoutProvider, (previous, next) {
      switch (next) {
        case AsyncData(:final value) when value == true:
          context.pushReplacementNamed(Routes.login);
        case AsyncError(:final error):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logoutProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.locale.home)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulate notification deep link to profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Simulating notification deep link to profile...'),
              duration: Duration(seconds: 1),
            ),
          );
          // Navigate directly to profile (will be caught by auth guard if not logged in)
          context.go(Routes.profile);
        },
        tooltip: 'Simulate Notification to Profile',
        child: const Icon(Icons.notifications),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.padding.p16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home, size: 100, color: Colors.blue),
              Gap(context.spacing.s16),
              Text(
                'Welcome to the Home Page!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Gap(context.spacing.s8),
              Text(
                'This is a protected route.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              Gap(context.spacing.s32),

              // Section for testing notification routing
              Card(
                child: Padding(
                  padding: EdgeInsets.all(context.padding.p16),
                  child: Column(
                    children: [
                      Text(
                        'Test Notification Routing',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Gap(context.spacing.s16),

                      // Collection notification (PUBLIC - no auth required)
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Simulating COLLECTION notification...',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          context.go(Routes.collection);
                        },
                        icon: const Icon(Icons.collections),
                        label: const Text('Collection Notification (PUBLIC)'),
                      ),
                      Gap(context.spacing.s8),

                      // Cart notification (PROTECTED - auth required)
                      FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Simulating CART notification...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          context.go(Routes.cart);
                        },
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Cart Notification (PROTECTED)'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      Gap(context.spacing.s8),

                      // Profile navigation
                      OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(Routes.profile);
                        },
                        icon: const Icon(Icons.person),
                        label: Text('Go to ${context.locale.profile}'),
                      ),

                      OutlinedButton(
                        onPressed: () {
                          context.pushNamed(Routes.notification);
                        },
                        child: const Text('Go to notification'),
                      ),
                    ],
                  ),
                ),
              ),

              Gap(context.spacing.s32),

              // Logout button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(logoutProvider.notifier).call();
                },
                icon: const Icon(Icons.logout),
                label: state.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.locale.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

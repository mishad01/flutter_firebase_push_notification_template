import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const HeadingSmallText('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.padding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeadingLargeText('Settings Page'),
            Gap(context.spacing.s16),
            const Text(
              'This is a protected page that requires authentication. '
              'If you accessed this directly while logged out, you should '
              'have been redirected to login first.',
            ),
            Gap(context.spacing.s24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(context.padding.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeadingSmallText('Navigation Test'),
                    Gap(context.spacing.s12),
                    const Text(
                      'Try accessing this page when logged out by going to '
                      '/settings directly.',
                    ),
                    Gap(context.spacing.s16),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.goNamed(Routes.home),
                          child: const Text('Go to Home'),
                        ),
                        Gap(context.spacing.s8),
                        TextButton(
                          onPressed: () => context.goNamed(Routes.profile),
                          child: const Text('Go to Profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

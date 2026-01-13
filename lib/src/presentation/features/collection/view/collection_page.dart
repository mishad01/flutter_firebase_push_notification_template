import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection')),
      body: Padding(
        padding: EdgeInsets.all(context.padding.p16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.collections, size: 100, color: Colors.purple),
            Gap(context.spacing.s16),
            Text(
              'Collection Page',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Gap(context.spacing.s8),
            Text(
              'This is a public route accessible to all users.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Gap(context.spacing.s16),
            const Text(
              '🎨 Browse collections without authentication!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

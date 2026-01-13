import 'package:flutter/material.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    this.collectionId,
    this.collectionTitle,
  });

  final String? collectionId;
  final String? collectionTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collectionTitle ?? 'Collection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.collections, size: 100),
            const SizedBox(height: 20),
            Text(
              collectionTitle ?? 'Collection',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (collectionId != null) ...[
              const SizedBox(height: 10),
              Text('Collection ID: $collectionId'),
            ],
          ],
        ),
      ),
    );
  }
}

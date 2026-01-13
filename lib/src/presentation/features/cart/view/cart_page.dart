import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key, this.checkOutUrl});

  final String? checkOutUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Your Cart',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (checkOutUrl != null) ...[
              const SizedBox(height: 10),
              Text('Checkout URL: $checkOutUrl'),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Padding(
        padding: EdgeInsets.all(context.padding.p16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, size: 100, color: Colors.orange),
            Gap(context.spacing.s16),
            Text(
              'Shopping Cart',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Gap(context.spacing.s8),
            Text(
              'This is a PROTECTED route that requires authentication.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Gap(context.spacing.s16),
            const Text(
              '🛒 You successfully accessed the cart after login!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap(context.spacing.s24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(context.padding.p16),
                child: Column(
                  children: [
                    const Text(
                      'Cart Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap(context.spacing.s8),
                    const Text('No items in cart'),
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

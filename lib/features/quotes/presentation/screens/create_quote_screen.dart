// lib/features/quotes/presentation/screens/create_quote_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateQuoteScreen extends StatelessWidget {
  const CreateQuoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Quote creation is handled from the cart screen
    // This redirects users to the cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/cart');
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Redirecting to cart...'),
            SizedBox(height: 8),
            Text(
              'Create quotes from your cart',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

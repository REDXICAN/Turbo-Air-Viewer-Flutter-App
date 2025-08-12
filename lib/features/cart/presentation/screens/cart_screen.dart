// lib/features/cart/presentation/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/product_image_helper.dart';

// Cart provider using Realtime Database
final cartProvider = StreamProvider<List<CartItem>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);

  return dbService.getCartItems().asyncMap((items) async {
    // Fetch product details for each cart item
    final List<CartItem> cartItems = [];

    for (final item in items) {
      final productData = await dbService.getProduct(item['product_id']);

      cartItems.add(CartItem(
        id: item['id'],
        userId: item['user_id'],
        productId: item['product_id'],
        quantity: item['quantity'],
        product: productData != null ? Product.fromJson(productData) : null,
        createdAt: item['created_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(item['created_at'])
            : null,
      ));
    }

    return cartItems;
  });
});

// Clients provider
final clientsProvider = StreamProvider<List<Client>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);

  return dbService.getClients().map((clientsList) {
    return clientsList.map((json) => Client.fromJson(json)).toList();
  });
});

// Cart client provider
final cartClientProvider = StateProvider<Client?>((ref) => null);

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _taxRateController = TextEditingController(text: '8.0');
  bool _isCreatingQuote = false;

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final selectedClient = ref.watch(cartClientProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: cartAsync.when(
              data: (items) => items.isNotEmpty ? () => _clearCart() : null,
              loading: () => null,
              error: (_, __) => null,
            ),
          ),
        ],
      ),
      body: cartAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 100,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final subtotal = _calculateSubtotal(items);
          final taxRate = double.tryParse(_taxRateController.text) ?? 0;
          final taxAmount = subtotal * (taxRate / 100);
          final total = subtotal + taxAmount;

          return Column(
            children: [
              // Client Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          selectedClient != null
                              ? Icons.business
                              : Icons.person_add,
                        ),
                      ),
                      title: Text(
                        selectedClient?.company ?? 'Select Client',
                      ),
                      subtitle: selectedClient?.contactName != null
                          ? Text(selectedClient!.contactName!)
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _selectClient,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final product = item.product;
                    final imagePath = product != null
                        ? ProductImageHelper.getImagePath(product.sku)
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: imagePath != null
                            ? Image.asset(
                                imagePath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: theme.disabledColor.withOpacity(0.1),
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: theme.disabledColor.withOpacity(0.1),
                                child: const Icon(Icons.inventory_2),
                              ),
                        title: Text(product?.displayName ?? 'Unknown Product'),
                        subtitle: Text(
                          '\$${((product?.price ?? 0) * item.quantity).toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(item, -1),
                            ),
                            Text(
                              item.quantity.toString(),
                              style: theme.textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(item, 1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeItem(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Summary and Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tax Rate Input
                    Row(
                      children: [
                        Text('Tax Rate (%)', style: theme.textTheme.bodyMedium),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _taxRateController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: theme.textTheme.bodyMedium),
                        Text('\$${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tax', style: theme.textTheme.bodyMedium),
                        Text('\$${taxAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: theme.textTheme.titleLarge),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                selectedClient != null && !_isCreatingQuote
                                    ? () => _createQuote(items, selectedClient!)
                                    : null,
                            icon: _isCreatingQuote
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.receipt_long),
                            label: Text(_isCreatingQuote
                                ? 'Creating...'
                                : 'Create Quote'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading cart: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(cartProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) {
      return sum + ((item.product?.price ?? 0) * item.quantity);
    });
  }

  Future<void> _selectClient() async {
    final client = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientSelectorScreen(),
      ),
    );

    if (client != null) {
      ref.read(cartClientProvider.notifier).state = client;
    }
  }

  Future<void> _updateQuantity(CartItem item, int change) async {
    final newQuantity = item.quantity + change;
    if (newQuantity <= 0) {
      await _removeItem(item);
      return;
    }

    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateCartItem(item.id, newQuantity);
    ref.invalidate(cartProvider);
  }

  Future<void> _removeItem(CartItem item) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.removeFromCart(item.id);
    ref.invalidate(cartProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to clear all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final dbService = ref.read(databaseServiceProvider);
    await dbService.clearCart();
    ref.invalidate(cartProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart cleared')),
      );
    }
  }

  Future<void> _createQuote(List<CartItem> items, Client client) async {
    setState(() => _isCreatingQuote = true);

    try {
      final dbService = ref.read(databaseServiceProvider);
      final subtotal = _calculateSubtotal(items);
      final taxRate = double.tryParse(_taxRateController.text) ?? 0;
      final taxAmount = subtotal * (taxRate / 100);
      final total = subtotal + taxAmount;

      // Prepare quote items
      final quoteItems = items
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': item.product?.price ?? 0,
                'total_price': (item.product?.price ?? 0) * item.quantity,
              })
          .toList();

      // Create quote
      final quoteId = await dbService.createQuote(
        clientId: client.id,
        items: quoteItems,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: total,
      );

      // Clear cart after creating quote
      await dbService.clearCart();
      ref.invalidate(cartProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to quote details
        Navigator.pushReplacementNamed(
          context,
          '/quotes/$quoteId',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingQuote = false);
    }
  }
}

// Client selector screen
class ClientSelectorScreen extends ConsumerWidget {
  const ClientSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Client'),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: clientsAsync.when(
        data: (clients) => ListView.builder(
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(client.company[0].toUpperCase()),
              ),
              title: Text(client.company),
              subtitle:
                  client.contactName != null ? Text(client.contactName!) : null,
              onTap: () => Navigator.pop(context, client),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading clients: $error'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../clients/presentation/screens/clients_screen.dart'
    show Client, selectedClientProvider;

// Cart provider
final cartProvider = FutureProvider<List<CartItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  final selectedClient = ref.watch(selectedClientProvider);

  if (user == null || selectedClient == null) return [];

  final response = await supabase
      .from('cart_items')
      .select('*, products(*)')
      .eq('user_id', user.id)
      .eq('client_id', selectedClient.id);

  return (response as List).map((json) => CartItem.fromJson(json)).toList();
});

// Tax rate provider
final taxRateProvider = StateProvider<double>((ref) => 8.0);

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final taxRate = ref.watch(taxRateProvider);

    if (selectedClient == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
          backgroundColor: const Color(0xFF20429C),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 80, color: Colors.orange[400]),
              const SizedBox(height: 16),
              const Text(
                'No client selected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please select a client from the Clients tab first'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to clients tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20429C),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Clients'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: const Color(0xFF20429C),
        foregroundColor: Colors.white,
      ),
      body: cartAsync.when(
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Cart is Empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Add products from the Products tab to create a quote'),
                ],
              ),
            );
          }

          // Calculate totals
          double subtotal = 0;
          for (var item in cartItems) {
            subtotal += (item.product?.price ?? 0) * item.quantity;
          }
          double taxAmount = subtotal * (taxRate / 100);
          double total = subtotal + taxAmount;

          return Column(
            children: [
              // Client info bar
              Container(
                color: Colors.blue[50],
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Client: ${selectedClient.company}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Cart items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItem(item);
                  },
                ),
              ),

              // Summary section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tax rate input
                    Row(
                      children: [
                        const Text('Tax Rate (%):'),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            initialValue: taxRate.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final newRate = double.tryParse(value) ?? 8.0;
                              ref.read(taxRateProvider.notifier).state =
                                  newRate;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Totals
                    _buildSummaryRow('Subtotal', subtotal),
                    _buildSummaryRow(
                        'Tax (${taxRate.toStringAsFixed(1)}%)', taxAmount),
                    const Divider(thickness: 2),
                    _buildSummaryRow('Total', total, isTotal: true),

                    const SizedBox(height: 16),

                    // Export buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _emailQuote(
                                cartItems, subtotal, taxAmount, total),
                            icon: const Icon(Icons.email),
                            label: const Text('Email Quote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20429C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportPDF(
                                cartItems, subtotal, taxAmount, total),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Export PDF'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportExcel(
                                cartItems, subtotal, taxAmount, total),
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Export Excel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _clearCart,
                            icon: const Icon(Icons.clear, color: Colors.red),
                            label: const Text('Clear Cart',
                                style: TextStyle(color: Colors.red)),
                            style: TextButton.styleFrom(
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
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.sku,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (product.productType != null)
                    Text(
                      product.productType!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      color: Color(0xFF20429C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () => _updateQuantity(item, item.quantity - 1),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _updateQuantity(item, item.quantity + 1),
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Total price
            SizedBox(
              width: 80,
              child: Text(
                '\$${((product.price ?? 0) * item.quantity).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeItem(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF20429C) : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(item);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('cart_items')
          .update({'quantity': newQuantity}).eq('id', item.id);

      ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantity: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('cart_items').delete().eq('id', item.id);

      ref.invalidate(cartProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from cart')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to clear all items from the cart?'),
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

    if (confirmed != true) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final selectedClient = ref.read(selectedClientProvider);

      if (user != null && selectedClient != null) {
        await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', user.id)
            .eq('client_id', selectedClient.id);

        ref.invalidate(cartProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cart cleared')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cart: $e')),
        );
      }
    }
  }

  void _emailQuote(
      List<CartItem> items, double subtotal, double tax, double total) {
    // TODO: Implement email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email functionality coming soon')),
    );
  }

  void _exportPDF(
      List<CartItem> items, double subtotal, double tax, double total) {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export coming soon')),
    );
  }

  void _exportExcel(
      List<CartItem> items, double subtotal, double tax, double total) {
    // TODO: Implement Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export coming soon')),
    );
  }
}

// Cart item model
class CartItem {
  final String id;
  final String userId;
  final String clientId;
  final String productId;
  final int quantity;
  final Product? product;
  final DateTime createdAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.clientId,
    required this.productId,
    required this.quantity,
    this.product,
    required this.createdAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      clientId: json['client_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      product:
          json['products'] != null ? Product.fromJson(json['products']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Product model for cart
class Product {
  final String id;
  final String sku;
  final String? productType;
  final double? price;

  Product({
    required this.id,
    required this.sku,
    this.productType,
    this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'],
      productType: json['product_type'],
      price: json['price']?.toDouble(),
    );
  }
}

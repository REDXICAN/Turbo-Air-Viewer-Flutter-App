// lib/features/cart/presentation/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../clients/presentation/screens/clients_screen.dart'
    show clientsProvider;
import '../../../../core/services/email_service.dart';
import '../../../../core/services/export_service.dart';

// Cart provider
final cartProvider = FutureProvider<List<CartItem>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('cart_items')
      .select('*, products(*)')
      .eq('user_id', user.id);

  return (response as List).map((json) => CartItem.fromJson(json)).toList();
});

// Cart client provider - separate from clients screen selection
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Cart'),
        backgroundColor: const Color(0xFF20429C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCart,
            tooltip: 'Clear Cart',
          ),
        ],
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
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add products to get started'),
                ],
              ),
            );
          }

          final subtotal = _calculateSubtotal(cartItems);
          final taxRate = double.tryParse(_taxRateController.text) ?? 0;
          final taxAmount = subtotal * (taxRate / 100);
          final total = subtotal + taxAmount;

          return Column(
            children: [
              // Client selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Client',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (selectedClient != null)
                      Card(
                        color: Colors.green[50],
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: Colors.green),
                          title: Text(selectedClient.company),
                          subtitle: selectedClient.contactName != null
                              ? Text(selectedClient.contactName!)
                              : null,
                          trailing: TextButton(
                            onPressed: () => _selectClient(),
                            child: const Text('Change'),
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _selectClient,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Select Client'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                  ],
                ),
              ),

              // Cart items
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

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
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
                          width: 80,
                          child: TextField(
                            controller: _taxRateController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Totals
                    _buildSummaryRow('Subtotal', subtotal),
                    _buildSummaryRow('Tax ($taxRate%)', taxAmount),
                    const Divider(),
                    _buildSummaryRow('Total', total, isBold: true),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selectedClient != null &&
                                    !_isCreatingQuote
                                ? () => _createQuote(cartItems, selectedClient)
                                : null,
                            icon: _isCreatingQuote
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.receipt),
                            label: Text(_isCreatingQuote
                                ? 'Creating...'
                                : 'Create Quote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20429C),
                              foregroundColor: Colors.white,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image placeholder
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

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product?.sku ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.product?.productType != null)
                    Text(
                      item.product!.productType!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  Text(
                    '\$${(item.product?.price ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF20429C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                IconButton(
                  onPressed: () => _updateQuantity(item, item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.red,
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _updateQuantity(item, item.quantity + 1),
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                ),
              ],
            ),

            // Remove button
            IconButton(
              onPressed: () => _removeFromCart(item),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: isBold ? const Color(0xFF20429C) : null,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(
        0, (sum, item) => sum + (item.product?.price ?? 0) * item.quantity);
  }

  void _selectClient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientSelectorScreen(),
      ),
    ).then((client) {
      if (client != null) {
        ref.read(cartClientProvider.notifier).state = client;
      }
    });
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeFromCart(item);
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

  Future<void> _removeFromCart(CartItem item) async {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items?'),
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

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('cart_items').delete().eq('user_id', user.id);
        ref.invalidate(cartProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cart: $e')),
        );
      }
    }
  }

  Future<void> _createQuote(List<CartItem> items, Client client) async {
    setState(() => _isCreatingQuote = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final subtotal = _calculateSubtotal(items);
      final taxRate = double.tryParse(_taxRateController.text) ?? 0;
      final taxAmount = subtotal * (taxRate / 100);
      final total = subtotal + taxAmount;

      // Generate quote number
      final quoteNumber = 'Q${DateTime.now().millisecondsSinceEpoch}';

      // Create quote
      final quoteResponse = await supabase
          .from('quotes')
          .insert({
            'user_id': user.id,
            'client_id': client.id,
            'quote_number': quoteNumber,
            'subtotal': subtotal,
            'tax_rate': taxRate,
            'tax_amount': taxAmount,
            'total_amount': total,
            'status': 'draft',
          })
          .select()
          .single();

      final quoteId = quoteResponse['id'];

      // Add quote items
      for (final item in items) {
        await supabase.from('quote_items').insert({
          'quote_id': quoteId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': item.product?.price ?? 0,
          'total_price': (item.product?.price ?? 0) * item.quantity,
        });
      }

      // Clear cart
      await supabase.from('cart_items').delete().eq('user_id', user.id);

      if (mounted) {
        ref.invalidate(cartProvider);

        // Show success and options
        _showQuoteCreatedDialog(quoteNumber, quoteId, client);
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

  void _showQuoteCreatedDialog(
      String quoteNumber, String quoteId, Client client) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quote Created!'),
        content: Text('Quote #$quoteNumber has been created successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendQuoteEmail(quoteId, client);
            },
            child: const Text('Send Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportQuotePDF(quoteId);
            },
            child: const Text('Export PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportQuoteExcel(quoteId);
            },
            child: const Text('Export Excel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuoteEmail(String quoteId, Client client) async {
    try {
      await EmailService.sendQuoteEmail(
        quoteId: quoteId,
        clientEmail: client.contactEmail ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportQuotePDF(String quoteId) async {
    try {
      final pdfBytes = await ExportService.generateQuotePDF(quoteId);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'quote_$quoteId.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportQuoteExcel(String quoteId) async {
    try {
      final excelBytes = await ExportService.generateQuoteExcel(quoteId);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quote_$quoteId.xlsx');
      await file.writeAsBytes(excelBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Quote Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting Excel: $e')),
        );
      }
    }
  }
}

// Client selector screen
class ClientSelectorScreen extends ConsumerWidget {
  const ClientSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Client'),
        backgroundColor: const Color(0xFF20429C),
        foregroundColor: Colors.white,
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
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// Models
class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final Product? product;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      product:
          json['products'] != null ? Product.fromJson(json['products']) : null,
    );
  }
}

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

class Client {
  final String id;
  final String company;
  final String? contactName;
  final String? contactEmail;

  Client({
    required this.id,
    required this.company,
    this.contactName,
    this.contactEmail,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      company: json['company'],
      contactName: json['contact_name'],
      contactEmail: json['contact_email'],
    );
  }
}

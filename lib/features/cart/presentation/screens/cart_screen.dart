// lib/features/cart/presentation/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../../core/services/firebase_database_service.dart';
import '../../../../core/services/email_service.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/utils/product_image_helper.dart';
import '../../../clients/presentation/screens/clients_screen.dart'
    show selectedClientProvider;
import '../../domain/models/cart_item.dart';
import '../../domain/models/client.dart';
import '../../domain/models/product.dart';

// Cart provider using Firebase Realtime Database
final cartProvider = StreamProvider<List<CartItem>>((ref) {
  return FirebaseDatabaseService.getCartItems().map((items) {
    return items.map((item) => CartItem.fromJson(item)).toList();
  });
});

// Cart client provider - separate from clients screen selection
final cartClientProvider = StateProvider<Client?>((ref) => null);

// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (items) => items.length,
    orElse: () => 0,
  );
});

// Cart total provider
final cartTotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (items) => items.fold(0.0, (sum, item) {
      return sum + ((item.product?.price ?? 0) * item.quantity);
    }),
    orElse: () => 0.0,
  );
});

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  final _taxRateController = TextEditingController(text: '8.0');
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isCreatingQuote = false;
  bool _showNotes = false;
  bool _includeShipping = false;
  double _shippingCost = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  Future<void> _loadAppSettings() async {
    final settings = await FirebaseDatabaseService.getAppSettings();
    if (mounted) {
      setState(() {
        _taxRateController.text =
            ((settings['tax_rate'] ?? 0.08) * 100).toString();
      });
    }
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final selectedClient = ref.watch(selectedClientProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Cart'),
            if (cartItemCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$cartItemCount items',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (cartItemCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: cartAsync.maybeWhen(
                data: (items) => items.isNotEmpty && selectedClient != null
                    ? () => _exportPDF(items, selectedClient)
                    : null,
                orElse: () => null,
              ),
              tooltip: 'Export PDF',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: cartAsync.maybeWhen(
                data: (items) =>
                    items.isNotEmpty ? () => _shareCart(items) : null,
                orElse: () => null,
              ),
              tooltip: 'Share Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: cartAsync.maybeWhen(
                data: (items) => items.isNotEmpty ? _clearCart : null,
                orElse: () => null,
              ),
              tooltip: 'Clear Cart',
            ),
          ],
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: cartAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading cart...'),
              ],
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading cart',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(cartProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyCart();
            }

            return Column(
              children: [
                // Client Selection Banner
                _buildClientSelectionBanner(selectedClient),

                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1, // +1 for additional options
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _buildAdditionalOptions();
                      }
                      final item = items[index];
                      return _buildCartItem(item, index);
                    },
                  ),
                ),

                // Summary and Actions
                _buildSummarySection(items, selectedClient),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add products to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/products'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSelectionBanner(Client? selectedClient) {
    if (selectedClient == null) {
      return Container(
        color: Colors.orange.shade100,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No client selected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Please select a client to create a quote',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/clients'),
              icon: const Icon(Icons.person_add),
              label: const Text('Select Client'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.green.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedClient.company,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selectedClient.contactName != null)
                  Text(
                    selectedClient.contactName!,
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/clients'),
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(item),
          child: ExpansionTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                image: ProductImageHelper.hasImage(product.sku)
                    ? DecorationImage(
                        image: AssetImage(
                          ProductImageHelper.getImagePath(product.sku),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !ProductImageHelper.hasImage(product.sku)
                  ? const Icon(Icons.inventory_2, color: Colors.grey)
                  : null,
            ),
            title: Text(
              product.sku,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productType ?? 'Product',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  product.formattedPrice,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildQuantityControls(item),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 10)),
                    Text(
                      '\$${((product.price ?? 0) * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.description != null)
                      _buildDetailRow('Description', product.description!),
                    if (product.dimensions != null)
                      _buildDetailRow('Dimensions', product.dimensions!),
                    if (product.voltage != null)
                      _buildDetailRow('Voltage', product.voltage!),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _removeItem(item),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: item.quantity > 1
                ? () => _updateQuantity(item, item.quantity - 1)
                : null,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _updateQuantity(item, item.quantity + 1),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalOptions() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Option
            CheckboxListTile(
              title: const Text('Include Shipping'),
              subtitle: _includeShipping
                  ? TextField(
                      decoration: const InputDecoration(
                        labelText: 'Shipping Cost',
                        prefixText: '\$',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _shippingCost = double.tryParse(value) ?? 0.0;
                        });
                      },
                    )
                  : null,
              value: _includeShipping,
              onChanged: (value) {
                setState(() {
                  _includeShipping = value ?? false;
                  if (!_includeShipping) _shippingCost = 0.0;
                });
              },
            ),

            // Notes Option
            CheckboxListTile(
              title: const Text('Add Notes'),
              value: _showNotes,
              onChanged: (value) {
                setState(() {
                  _showNotes = value ?? false;
                });
              },
            ),

            if (_showNotes)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add any special instructions or notes...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(List<CartItem> items, Client? selectedClient) {
    final subtotal = _calculateSubtotal(items);
    final tax = _calculateTax(items);
    final total = _calculateTotal(items);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tax Rate Input
          Row(
            children: [
              const Text('Tax Rate (%):'),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _taxRateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _showTaxInfo,
                child: const Text('Tax Info'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Totals
          _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          if (_includeShipping && _shippingCost > 0)
            _buildSummaryRow(
                'Shipping', '\$${_shippingCost.toStringAsFixed(2)}'),
          _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
          const Divider(thickness: 2),
          _buildSummaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isBold: true,
            isLarge: true,
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/products'),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add More'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: selectedClient != null && !_isCreatingQuote
                      ? () => _createQuote(items, selectedClient)
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
                  label:
                      Text(_isCreatingQuote ? 'Creating...' : 'Create Quote'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 20 : (isBold ? 18 : 16),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : (isBold ? 18 : 16),
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isLarge ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty || value == '-') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) {
      return sum + ((item.product?.price ?? 0) * item.quantity);
    });
  }

  double _calculateTax(List<CartItem> items) {
    final subtotal = _calculateSubtotal(items) + _shippingCost;
    final taxRate = double.tryParse(_taxRateController.text) ?? 0;
    return subtotal * (taxRate / 100);
  }

  double _calculateTotal(List<CartItem> items) {
    return _calculateSubtotal(items) + _shippingCost + _calculateTax(items);
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(item);
      return;
    }

    try {
      await FirebaseDatabaseService.updateCartItemQuantity(
        item.id,
        newQuantity,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await FirebaseDatabaseService.removeFromCart(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product?.sku ?? 'Item'} removed from cart'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Re-add the item
                await FirebaseDatabaseService.addToCart(
                  productId: item.productId,
                  clientId: item.clientId,
                  quantity: item.quantity,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseDatabaseService.clearCart();
      ref.invalidate(cartProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createQuote(List<CartItem> items, Client client) async {
    setState(() => _isCreatingQuote = true);

    try {
      final subtotal = _calculateSubtotal(items);
      final taxRate = double.tryParse(_taxRateController.text) ?? 0;
      final taxAmount = _calculateTax(items);
      final total = _calculateTotal(items);

      // Prepare quote items
      final quoteItems = items
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': item.product?.price ?? 0,
                'total_price': (item.product?.price ?? 0) * item.quantity,
              })
          .toList();

      // Create quote using Firebase Database Service
      final quoteId = await FirebaseDatabaseService.createQuote(
        clientId: client.id,
        items: quoteItems,
        subtotal: subtotal,
        taxRate: taxRate,
        taxAmount: taxAmount,
        totalAmount: total,
        shipping: _includeShipping ? _shippingCost : 0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Clear cart after creating quote
      await FirebaseDatabaseService.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quote created successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/quotes');
              },
            ),
          ),
        );

        // Reset form
        setState(() {
          _showNotes = false;
          _includeShipping = false;
          _shippingCost = 0.0;
          _notesController.clear();
        });
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

  void _showTaxInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Information'),
        content: const Text(
          'The tax rate is applied to the subtotal amount. '
          'You can adjust the tax rate based on your location '
          'and business requirements.\n\n'
          'Default tax rate is 8%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(List<CartItem> items, Client client) async {
    // TODO: Implement PDF export using ExportService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );
  }

  Future<void> _shareCart(List<CartItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('Cart Summary');
    buffer.writeln('=' * 30);

    for (var item in items) {
      final product = item.product;
      if (product != null) {
        buffer.writeln('${product.sku} x${item.quantity}');
        buffer.writeln('  Price: ${product.formattedPrice}');
        buffer.writeln(
            '  Total: \$${((product.price ?? 0) * item.quantity).toStringAsFixed(2)}');
        buffer.writeln('');
      }
    }

    buffer.writeln('-' * 30);
    buffer
        .writeln('Subtotal: \$${_calculateSubtotal(items).toStringAsFixed(2)}');
    buffer.writeln('Tax: \$${_calculateTax(items).toStringAsFixed(2)}');
    buffer.writeln('Total: \$${_calculateTotal(items).toStringAsFixed(2)}');

    await Share.share(buffer.toString());
  }
}

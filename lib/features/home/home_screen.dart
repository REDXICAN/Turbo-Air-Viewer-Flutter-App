// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../../core/models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user from Firebase Auth
    final user = ref.watch(currentUserProvider);

    // Get user profile for additional data
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final userProfile = userProfileAsync.valueOrNull;

    final recentQuotes = ref.watch(recentQuotesProvider);
    final totalClientsAsync = ref.watch(totalClientsProvider);
    final totalQuotesAsync = ref.watch(totalQuotesProvider);
    final cartItemCountAsync = ref.watch(cartItemCountProvider);
    final totalProductsAsync = ref.watch(totalProductsProvider);

    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Welcome, ${userProfile?.name ?? user?.displayName ?? user?.email ?? 'User'}',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
              ),
              delegate: SliverChildListDelegate([
                _buildStatCard(
                  context,
                  'Total Clients',
                  totalClientsAsync.when(
                    data: (value) => value.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.people,
                  Colors.blue,
                  () => context.go('/clients'),
                ),
                _buildStatCard(
                  context,
                  'Total Quotes',
                  totalQuotesAsync.when(
                    data: (value) => value.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.receipt,
                  Colors.green,
                  () => context.go('/quotes'),
                ),
                _buildStatCard(
                  context,
                  'Cart Items',
                  cartItemCountAsync.when(
                    data: (value) => value.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.shopping_cart,
                  Colors.orange,
                  () => context.go('/cart'),
                ),
                _buildStatCard(
                  context,
                  'Products',
                  totalProductsAsync.when(
                    data: (value) => value.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  Icons.inventory,
                  Colors.purple,
                  () => context.go('/products'),
                ),
              ]),
            ),
          ),
          recentQuotes.when(
            data: (quotes) {
              if (quotes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: SizedBox.shrink(),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Quotes',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      ...quotes.take(5).map((quote) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.receipt),
                              title: Text(quote.quoteNumber),
                              subtitle: Text(
                                  '\${quote.totalAmount.toStringAsFixed(2)}'),
                              trailing: Text(
                                _formatDate(quote.createdAt),
                                style: theme.textTheme.bodySmall,
                              ),
                              onTap: () {
                                _showQuoteDetails(context, quote);
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showQuoteDetails(BuildContext context, Quote quote) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quote #${quote.quoteNumber}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Subtotal',
                            '\${quote.subtotal.toStringAsFixed(2)}'),
                        _buildDetailRow('Tax (${quote.taxRate}%)',
                            '\${quote.taxAmount.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildDetailRow(
                          'Total',
                          '\${quote.totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Items (${quote.items.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...quote.items.map((item) {
                    final product = item.product;
                    final sku = product?['sku'] ?? 'Unknown';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sku,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item.quantity} × \${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

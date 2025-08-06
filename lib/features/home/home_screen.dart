import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import '../products/presentation/products_screen.dart';
import '../cart/presentation/screens/cart_screen.dart';
import '../clients/presentation/screens/clients_screen.dart';
import '../quotes/presentation/screens/quotes_screen.dart'
    hide Quote, QuoteItem, Client, Product;
import '../profile/presentation/screens/profile_screen.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../../core/widgets/sync_indicator.dart';
import '../../core/models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Products',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Clients',
    ),
    NavigationDestination(
      icon: Badge(
        label: Text('0'),
        child: Icon(Icons.shopping_cart_outlined),
      ),
      selectedIcon: Badge(
        label: Text('0'),
        child: Icon(Icons.shopping_cart),
      ),
      label: 'Cart',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_outlined),
      selectedIcon: Icon(Icons.receipt),
      label: 'Quotes',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cartItemCountAsync = ref.watch(cartItemCountProvider);
    final cartItemCount = cartItemCountAsync.valueOrNull ?? 0;

    // Update cart badge
    final destinations = List<NavigationDestination>.from(_destinations);
    destinations[3] = NavigationDestination(
      icon: Badge(
        label: Text('$cartItemCount'),
        isLabelVisible: cartItemCount > 0,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      selectedIcon: Badge(
        label: Text('$cartItemCount'),
        isLabelVisible: cartItemCount > 0,
        child: const Icon(Icons.shopping_cart),
      ),
      label: 'Cart',
    );

    return AdaptiveScaffold(
      useDrawer: false,
      selectedIndex: _selectedIndex,
      onSelectedIndexChange: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      destinations: destinations,
      body: (context) => _buildBody(),
      smallBody: (context) => _buildBody(),
      secondaryBody: null,
      leadingExtendedNavRail: _buildLeadingRail(),
      leadingUnextendedNavRail: _buildLeadingRail(),
      trailingNavRail: const SyncIndicator(),
    );
  }

  Widget _buildLeadingRail() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Image.asset(
          'assets/logos/turbo_air_logo.png',
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'Turbo Air',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ProductsScreen();
      case 2:
        return const ClientsScreen();
      case 3:
        return const CartScreen();
      case 4:
        return const QuotesScreen();
      case 5:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final recentQuotes = ref.watch(recentQuotesProvider);

    final totalClientsAsync = ref.watch(totalClientsProvider);
    final totalQuotesAsync = ref.watch(totalQuotesProvider);
    final cartItemCountAsync = ref.watch(cartItemCountProvider);
    final totalProductsAsync = ref.watch(totalProductsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          snap: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Welcome, ${user?.email ?? 'User'}',
              style: const TextStyle(color: Colors.white),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
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
              ),
            ]),
          ),
        ),
        if (recentQuotes.hasValue && recentQuotes.value!.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Quotes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ...recentQuotes.value!.take(5).map((quote) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(quote.quoteNumber),
                          subtitle:
                              Text('\$${quote.totalAmount.toStringAsFixed(2)}'),
                          trailing: Text(
                            _formatDate(quote.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            _showQuoteDetails(quote);
                          },
                        ),
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to relevant screen
          switch (title) {
            case 'Total Clients':
              setState(() => _selectedIndex = 2);
              break;
            case 'Total Quotes':
              setState(() => _selectedIndex = 4);
              break;
            case 'Cart Items':
              setState(() => _selectedIndex = 3);
              break;
            case 'Products':
              setState(() => _selectedIndex = 1);
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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

  void _showQuoteDetails(Quote quote) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
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

            // Quote details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Totals summary at top
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Subtotal',
                            '\$${quote.subtotal.toStringAsFixed(2)}'),
                        _buildDetailRow('Tax (${quote.taxRate}%)',
                            '\$${quote.taxAmount.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildDetailRow(
                          'Total',
                          '\$${quote.totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Items
                  Text(
                    'Items (${quote.items.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...quote.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product?.sku ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${item.quantity} × \$${item.unitPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
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

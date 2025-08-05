import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import '../features/products/presentation/screens/products_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/clients/presentation/screens/clients_screen.dart';
import '../features/quotes/presentation/screens/quotes_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../core/widgets/sync_indicator.dart';

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
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final cartItemCount = ref.watch(cartItemCountProvider);
    
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
    final user = ref.watch(currentUserProvider);
    final recentQuotes = ref.watch(recentQuotesProvider);
    final recentSearches = ref.watch(recentSearchesProvider);
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          snap: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('Welcome, ${user?.email ?? 'User'}'),
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
              childAspectRatio: 1.5,
            ),
            delegate: SliverChildListDelegate([
              _buildStatCard(
                context,
                'Total Clients',
                ref.watch(totalClientsProvider).toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Total Quotes',
                ref.watch(totalQuotesProvider).toString(),
                Icons.receipt,
                Colors.green,
              ),
              _buildStatCard(
                context,
                'Cart Items',
                ref.watch(cartItemCountProvider).toString(),
                Icons.shopping_cart,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                'Products',
                ref.watch(totalProductsProvider).toString(),
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
                      subtitle: Text('\$${quote.totalAmount.toStringAsFixed(2)}'),
                      trailing: Text(
                        _formatDate(quote.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        // Navigate to quote details
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
}
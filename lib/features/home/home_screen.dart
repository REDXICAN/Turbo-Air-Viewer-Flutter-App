import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/services/offline_service.dart';
import '../../core/services/cache_manager.dart';
import '../../core/models/models.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../products/presentation/products_screen.dart';
import '../cart/presentation/screens/cart_screen.dart';
import '../clients/presentation/screens/clients_screen.dart';
import '../quotes/presentation/screens/quotes_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../admin/presentation/screens/admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  int _syncQueueCount = 0;

  final CacheManager _cacheManager = CacheManager();

  // Statistics
  int _totalClients = 0;
  int _totalQuotes = 0;
  int _cartItems = 0;
  int _totalProducts = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkConnectivity();
    _loadStatistics();
    _listenToSyncStatus();
  }

  Future<void> _initializeServices() async {
    await OfflineService.initialize();
    await _cacheManager.initialize();

    // Initial sync if online
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      OfflineService.syncWithFirebase();
    }
  }

  void _checkConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });

      if (_isOnline) {
        OfflineService.syncPendingChanges();
      }
    });
  }

  void _listenToSyncStatus() {
    OfflineService.syncStatus.listen((status) {
      if (status == SyncStatus.completed) {
        setState(() {
          _syncQueueCount = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (status == SyncStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Will retry when online.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      setState(() {
        _syncQueueCount = OfflineService.getSyncQueueCount();
      });
    });
  }

  Future<void> _loadStatistics() async {
    try {
      final clients = await _cacheManager.getClients();
      final quotes = await _cacheManager.getQuotes();
      final products = await _cacheManager.getProducts();
      final cart = await OfflineService.getCart();

      setState(() {
        _totalClients = clients.length;
        _totalQuotes = quotes.length;
        _totalProducts = products.length;
        _cartItems = cart?.items.length ?? 0;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ProductsScreen();
      case 2:
        return const CartScreen();
      case 3:
        return const ClientsScreen();
      case 4:
        return const QuotesScreen();
      case 5:
        return const ProfileScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadStatistics();
        if (_isOnline) {
          await OfflineService.syncWithFirebase();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4169E1), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4169E1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.displayName ?? 'User'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (authProvider.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanelScreen(),
                          ),
                        );
                      },
                      tooltip: 'Admin Panel',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connection status
            if (!_isOnline || _syncQueueCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.orange : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isOnline ? Icons.sync : Icons.cloud_off,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isOnline
                            ? '$_syncQueueCount pending changes to sync'
                            : 'Offline mode - Changes will sync when online',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_isOnline && _syncQueueCount > 0)
                      TextButton(
                        onPressed: () {
                          OfflineService.syncPendingChanges();
                        },
                        child: const Text(
                          'Sync Now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            if (!_isOnline || _syncQueueCount > 0) const SizedBox(height: 16),

            // Statistics Grid
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Clients',
                  _totalClients.toString(),
                  Icons.people,
                  Colors.blue,
                  onTap: () => _onItemTapped(3),
                ),
                _buildStatCard(
                  'Total Quotes',
                  _totalQuotes.toString(),
                  Icons.receipt_long,
                  Colors.green,
                  onTap: () => _onItemTapped(4),
                ),
                _buildStatCard(
                  'Cart Items',
                  _cartItems.toString(),
                  Icons.shopping_cart,
                  Colors.orange,
                  onTap: () => _onItemTapped(2),
                ),
                _buildStatCard(
                  'Products',
                  _totalProducts.toString(),
                  Icons.inventory,
                  Colors.purple,
                  onTap: () => _onItemTapped(1),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Browse Products',
                    Icons.search,
                    () => _onItemTapped(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'New Client',
                    Icons.person_add,
                    () {
                      Navigator.pushNamed(context, '/clients/add');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View Cart',
                    Icons.shopping_cart,
                    () => _onItemTapped(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Create Quote',
                    Icons.add_circle,
                    () => _onItemTapped(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Quote>>(
              future: _cacheManager.getQuotes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No recent activity',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final recentQuotes = snapshot.data!
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                final displayQuotes = recentQuotes.take(5).toList();

                return Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayQuotes.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final quote = displayQuotes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(quote.status),
                          child: const Icon(
                            Icons.receipt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                            'Quote #${quote.quoteNumber ?? quote.id.substring(0, 8)}'),
                        subtitle: Text(
                          '${quote.clientName ?? 'Unknown'} - \$${quote.total.toStringAsFixed(2)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              quote.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(quote.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(quote.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/quotes/details',
                            arguments: quote.id,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: const Color(0xFF4169E1),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'TurboAir' : _getPageTitle()),
        backgroundColor: const Color(0xFF4169E1),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (_syncQueueCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _syncQueueCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                // Show notifications
              },
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await authProvider.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } else if (value == 'admin' && authProvider.isAdmin) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              } else if (value == 'sync') {
                OfflineService.syncWithFirebase();
              }
            },
            itemBuilder: (context) => [
              if (authProvider.isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: ListTile(
                    leading: Icon(Icons.admin_panel_settings),
                    title: Text('Admin Panel'),
                  ),
                ),
              const PopupMenuItem(
                value: 'sync',
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('Sync Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _getSelectedScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF2A2A2A),
        selectedItemColor: const Color(0xFF4169E1),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Products';
      case 2:
        return 'Cart';
      case 3:
        return 'Clients';
      case 4:
        return 'Quotes';
      case 5:
        return 'Profile';
      default:
        return 'TurboAir';
    }
  }
}

// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/quotes/presentation/screens/quotes_screen.dart';
import '../../features/quotes/presentation/screens/quote_detail_screen.dart';
import '../../features/quotes/presentation/screens/create_quote_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.uri.path.startsWith('/auth');

      // Fix line 172 - Cast user properly
      final user = state.extra as Map<String, dynamic>?;
      if (user != null && user['isAdmin'] == true) {
        // Handle admin logic if needed
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell
      ShellRoute(
        builder: (context, state, child) => MainNavigationShell(child: child),
        routes: [
          // Home
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),

          // Products
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
            routes: [
              GoRoute(
                path: ':productId',
                builder: (context, state) {
                  final productId = state.pathParameters['productId']!;
                  return ProductDetailScreen(productId: productId);
                },
              ),
            ],
          ),

          // Cart
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),

          // Clients
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),

          // Quotes
          GoRoute(
            path: '/quotes',
            builder: (context, state) => const QuotesScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateQuoteScreen(),
              ),
              GoRoute(
                path: ':quoteId',
                builder: (context, state) {
                  final quoteId = state.pathParameters['quoteId']!;
                  return QuoteDetailScreen(quoteId: quoteId);
                },
              ),
            ],
          ),

          // Profile
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Admin
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminPanelScreen(),
          ),
        ],
      ),
    ],
  );
});

// Main Navigation Shell with Bottom Navigation Bar
class MainNavigationShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  final List<String> _routes = [
    '/',
    '/products',
    '/cart',
    '/clients',
    '/quotes',
    '/profile',
  ];

  int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;

    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i]) && _routes[i] != '/') {
        return i;
      }
    }

    if (location.startsWith('/admin')) {
      return _routes.length;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserProfileAsync = ref.watch(currentUserProfileProvider);
    final isAdmin = currentUserProfileAsync.when(
      data: (profile) => profile?.isAdmin ?? false,
      loading: () => false,
      error: (_, __) => false,
    );

    final currentLocation = GoRouterState.of(context).uri.toString();
    final cartItemCountAsync = ref.watch(cartItemCountProvider);
    final cartItemCount = cartItemCountAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final routes = isAdmin ? [..._routes, '/admin'] : _routes;
    final selectedIndex = _calculateSelectedIndex(currentLocation);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, routes.length - 1),
        onDestinationSelected: (index) {
          if (index < routes.length) {
            context.go(routes[index]);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Badge(
              label: cartItemCount > 0 ? Text('$cartItemCount') : null,
              isLabelVisible: cartItemCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              label: cartItemCount > 0 ? Text('$cartItemCount') : null,
              isLabelVisible: cartItemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Quotes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          if (isAdmin)
            const NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}

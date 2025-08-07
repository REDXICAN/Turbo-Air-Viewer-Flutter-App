// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/clients/presentation/screens/clients_screen.dart';
import '../../features/quotes/presentation/screens/quotes_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// Static router instance for app.dart
class AppRouter {
  static late GoRouter router;

  static void initialize(Ref ref) {
    final authState = ref.watch(authStateProvider);

    router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoggedIn = authState.valueOrNull != null;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }

        if (isLoggedIn && isLoggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainNavigationShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/cart',
              builder: (context, state) => const CartScreen(),
            ),
            GoRoute(
              path: '/clients',
              builder: (context, state) => const ClientsScreen(),
            ),
            GoRoute(
              path: '/quotes',
              builder: (context, state) => const QuotesScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminPanelScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

// Provider to initialize router
final routerProvider = Provider<GoRouter>((ref) {
  AppRouter.initialize(ref);
  return AppRouter.router;
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
    // Handle root path
    if (location == '/') return 0;

    // Find matching route
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i]) && _routes[i] != '/') {
        return i;
      }
    }

    // Check for admin route
    if (location.startsWith('/admin')) {
      return _routes.length; // Admin is always last
    }

    return 0; // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser.valueOrNull?.isAdmin ?? false;
    final currentLocation = GoRouterState.of(context).uri.toString();
    final cartItemCountAsync = ref.watch(cartItemCountProvider);
    final cartItemCount = cartItemCountAsync.valueOrNull ?? 0;

    // Update routes if admin
    final routes = isAdmin ? [..._routes, '/admin'] : _routes;

    // Calculate selected index based on current location
    final selectedIndex = _calculateSelectedIndex(currentLocation);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(routes[index]);
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

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/offline_service.dart';
import 'core/services/cache_manager.dart';
import 'core/widgets/offline_status_widget.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firestore for offline support
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize offline service
  await OfflineService.initialize();

  // Pre-cache important collections for offline use
  await _preCacheData();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Pre-cache important data for offline use
Future<void> _preCacheData() async {
  try {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Enable offline for critical collections
      await OfflineService.enableOfflineCollection('products');
      await OfflineService.enableOfflineCollection('clients');
      await OfflineService.enableOfflineCollection('quotes');
      await OfflineService.enableOfflineCollection('cart_items');

      // Preload critical data using CacheManager
      await CacheManager.preloadCriticalData(user.uid);
    }
  } catch (e) {
    // Use debugPrint instead of print for production
    debugPrint('Error pre-caching data: $e');
  }
}

// Router provider - Replace Placeholder() with your actual screens
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;

      // Add your auth logic here
      if (!isLoggedIn && state.path != '/login') {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Placeholder(), // Replace with your main screen
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const Placeholder(), // Replace with your login screen
      ),
      // Add your other routes here
    ],
  );
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TurboAir Quote System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF20429C),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF20429C),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        // Wrap the entire app with offline status indicator
        return OfflineStatusWidget(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

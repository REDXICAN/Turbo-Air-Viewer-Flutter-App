// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/offline_service.dart';
import 'core/widgets/offline_status_widget.dart';
import 'app.dart';
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
    // Enable offline for critical collections
    await OfflineService.enableOfflineCollection('products');
    await OfflineService.enableOfflineCollection('clients');
    await OfflineService.enableOfflineCollection('quotes');
    await OfflineService.enableOfflineCollection('cart_items');
  } catch (e) {
    print('Error pre-caching data: $e');
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Your existing app code, but wrapped with OfflineStatusWidget
    return MaterialApp.router(
      title: 'TurboAir Quote System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Wrap the entire app with offline status indicator
        return OfflineStatusWidget(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

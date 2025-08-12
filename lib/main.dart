// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/offline_service.dart';
import 'core/services/realtime_database_service.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Realtime Database for offline support
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance
      .setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB cache

  // Initialize offline service with Hive
  await OfflineService.initialize();

  // Initialize database service
  final dbService = RealtimeDatabaseService();
  await dbService.enableOfflinePersistence();

  // Pre-cache important data for offline use
  await _preCacheData();

  runApp(
    const ProviderScope(
      child: TurboAirApp(),
    ),
  );
}

/// Pre-cache important data for offline use
Future<void> _preCacheData() async {
  try {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dbService = RealtimeDatabaseService();

      // Preload products
      dbService.getProducts().listen((products) {
        OfflineService.cacheProducts(products);
      });

      // Preload clients
      dbService.getClients().listen((clients) {
        OfflineService.cacheClients(clients);
      });

      // Preload quotes
      dbService.getQuotes().listen((quotes) {
        OfflineService.cacheQuotes(quotes);
      });

      // Preload cart items
      dbService.getCartItems().listen((items) {
        OfflineService.cacheCartItems(items);
      });
    }
  } catch (e) {
    debugPrint('Error pre-caching data: $e');
  }
}

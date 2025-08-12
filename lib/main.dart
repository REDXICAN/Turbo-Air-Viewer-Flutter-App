// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure Firebase Database for offline support
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance
      .setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB cache

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Open Hive boxes for offline caching
  await Hive.openBox('products_cache');
  await Hive.openBox('clients_cache');
  await Hive.openBox('quotes_cache');
  await Hive.openBox('cart_cache');
  await Hive.openBox('app_settings');

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
      // Keep references synced for offline access
      final database = FirebaseDatabase.instance;

      // Keep products synced
      database.ref('products').keepSynced(true);

      // Keep user's clients synced
      database
          .ref('clients')
          .orderByChild('user_id')
          .equalTo(user.uid)
          .keepSynced(true);

      // Keep user's quotes synced
      database
          .ref('quotes')
          .orderByChild('user_id')
          .equalTo(user.uid)
          .keepSynced(true);

      // Keep user's cart items synced
      database
          .ref('cart_items')
          .orderByChild('user_id')
          .equalTo(user.uid)
          .keepSynced(true);
    }
  } catch (e) {
    debugPrint('Error pre-caching data: $e');
  }
}

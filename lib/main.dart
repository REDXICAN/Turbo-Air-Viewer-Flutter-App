// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/offline_service.dart';
import 'core/services/cache_manager.dart';
import 'core/widgets/offline_status_widget.dart';
import 'firebase_options.dart';
import 'app.dart';

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

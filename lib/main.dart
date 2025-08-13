// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'dart:io' show Platform;
import 'core/services/offline_service.dart';
import 'core/services/realtime_database_service.dart';
import 'core/services/cache_manager.dart';
import 'core/services/sample_data_service.dart';
import 'core/services/app_logger.dart';
import 'core/config/env_config.dart';
import 'core/utils/error_handler.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Load environment variables FIRST
  try {
    await dotenv.load(fileName: ".env");
    // Don't log yet - logger not initialized
  } catch (e) {
    // Silent fail - will use fallback firebase_options.dart
    print('Warning: Failed to load .env file - using fallback firebase_options.dart: $e');
  }

  // Initialize Firebase with environment variables or fallback
  await Firebase.initializeApp(
    options: EnvConfig.isLoaded ? _getFirebaseOptions() : DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Crashlytics
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  }

  // NOW Initialize logging service after Firebase is ready
  await AppLogger.initialize(
    logLevel: kDebugMode ? Level.debug : Level.info,
    enableFirebaseLogs: !kDebugMode,
    enableConsoleLogs: true,
    allowedCategories: kDebugMode ? {} : {
      LogCategory.auth,
      LogCategory.error,
      LogCategory.security,
      LogCategory.business,
    },
  );

  // Initialize error handling
  await ErrorHandler.initialize();

  AppLogger.info('App initialization started', category: LogCategory.general);
  AppLogger.info('Environment variables loaded: ${EnvConfig.isLoaded}', category: LogCategory.general);

  // Configure Firebase Realtime Database for offline support
  // Note: setPersistenceEnabled is not supported on web platform
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance
        .setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB cache
    AppLogger.info('Firebase offline persistence enabled', category: LogCategory.database);
  }

  // Initialize offline service with Hive
  final timer = AppLogger.startTimer();
  await OfflineService.staticInitialize();
  AppLogger.logTimer('Offline service initialization', timer);
  
  // Initialize cache manager
  await CacheManager.initialize();
  AppLogger.info('Cache manager initialized', category: LogCategory.offline);

  // Initialize database service
  final dbService = RealtimeDatabaseService();
  await dbService.enableOfflinePersistence();
  AppLogger.info('Database service initialized', category: LogCategory.database);

  // Pre-cache important data for offline use
  await _preCacheData();
  
  // Initialize sample data if needed
  await SampleDataService.initializeSampleData();
  AppLogger.info('Sample data service initialized', category: LogCategory.database);

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
      AppLogger.info('Pre-caching data for user: ${user.email}', category: LogCategory.offline);
      final dbService = RealtimeDatabaseService();

      // Preload products
      dbService.getProducts().listen((products) {
        OfflineService.cacheProducts(products);
        AppLogger.debug('Cached ${products.length} products', category: LogCategory.offline);
      });

      // Preload clients
      dbService.getClients().listen((clients) {
        OfflineService.cacheClients(clients);
        AppLogger.debug('Cached ${clients.length} clients', category: LogCategory.offline);
      });

      // Preload quotes
      dbService.getQuotes().listen((quotes) {
        OfflineService.cacheQuotes(quotes);
        AppLogger.debug('Cached ${quotes.length} quotes', category: LogCategory.offline);
      });

      // Preload cart items
      dbService.getCartItems().listen((items) {
        OfflineService.cacheCartItems(items);
        AppLogger.debug('Cached ${items.length} cart items', category: LogCategory.offline);
      });
    } else {
      AppLogger.info('No user authenticated, skipping pre-cache', category: LogCategory.offline);
    }
  } catch (e) {
    AppLogger.error('Error pre-caching data', error: e, category: LogCategory.offline);
  }
}

/// Get Firebase options from environment variables
FirebaseOptions _getFirebaseOptions() {
  // Determine platform
  String apiKey;
  String appId;
  
  if (kIsWeb) {
    apiKey = EnvConfig.firebaseApiKeyWeb;
    appId = EnvConfig.firebaseAppIdWeb;
  } else if (Platform.isAndroid) {
    apiKey = EnvConfig.firebaseApiKeyAndroid;
    appId = EnvConfig.firebaseAppIdAndroid;
  } else if (Platform.isIOS) {
    apiKey = EnvConfig.firebaseApiKeyIos;
    appId = EnvConfig.firebaseAppIdIos;
  } else if (Platform.isWindows) {
    apiKey = EnvConfig.firebaseApiKeyWindows;
    appId = EnvConfig.firebaseAppIdWindows;
  } else {
    // Fallback to web config for other platforms
    apiKey = EnvConfig.firebaseApiKeyWeb;
    appId = EnvConfig.firebaseAppIdWeb;
  }
  
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: EnvConfig.firebaseMessagingSenderId,
    projectId: EnvConfig.firebaseProjectId,
    authDomain: EnvConfig.firebaseAuthDomain,
    databaseURL: EnvConfig.firebaseDatabaseUrl,
    storageBucket: EnvConfig.firebaseStorageBucket,
    measurementId: EnvConfig.firebaseMeasurementId,
  );
}

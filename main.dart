import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/services/offline_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  await OfflineService.registerAdapters();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    localStorage: const SupabaseLocalStorage(),
  );
  
  // Initialize offline storage
  await OfflineService.initialize();
  
  runApp(
    const ProviderScope(
      child: TurboAirApp(),
    ),
  );
}

/// Custom local storage implementation for Supabase
class SupabaseLocalStorage extends LocalStorage {
  const SupabaseLocalStorage();
  
  @override
  Future<void> initialize() async {
    // Already initialized in main
  }
  
  @override
  Future<String?> accessToken() async {
    final box = await Hive.openBox('auth');
    return box.get('access_token');
  }
  
  @override
  Future<void> persistSession(String persistSessionString) async {
    final box = await Hive.openBox('auth');
    await box.put('session', persistSessionString);
  }
  
  @override
  Future<void> removePersistedSession() async {
    final box = await Hive.openBox('auth');
    await box.delete('session');
  }
  
  @override
  Future<bool> hasAccessToken() async {
    final box = await Hive.openBox('auth');
    return box.containsKey('access_token');
  }
  
  @override
  Future<String?> getItem({required String key}) async {
    final box = await Hive.openBox('storage');
    return box.get(key);
  }
  
  @override
  Future<void> setItem({required String key, required String value}) async {
    final box = await Hive.openBox('storage');
    await box.put(key, value);
  }
  
  @override
  Future<void> removeItem({required String key}) async {
    final box = await Hive.openBox('storage');
    await box.delete(key);
  }
}
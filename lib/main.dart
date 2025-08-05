// Location: lib/main.dart
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
  
  // Check if configuration is valid
  if (AppConfig.supabaseUrl.isEmpty || 
      AppConfig.supabaseUrl.contains('your-project') ||
      AppConfig.supabaseAnonKey.isEmpty || 
      AppConfig.supabaseAnonKey.contains('your-anon-key')) {
    print('⚠️ WARNING: Supabase configuration not found!');
    print('Please run with: flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx');
    print('Or use the run_local.bat script');
    
    // Show error UI
    runApp(const ConfigErrorApp());
    return;
  }
  
  // Register Hive adapters (simplified without code generation)
  // await OfflineService.registerAdapters();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  // Initialize offline storage
  // await OfflineService.initialize();
  
  runApp(
    const ProviderScope(
      child: TurboAirApp(),
    ),
  );
}

// Error app to show when configuration is missing
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF20429C),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Supabase configuration not found.\nPlease run with environment variables:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'flutter run --dart-define=SUPABASE_URL=xxx\n--dart-define=SUPABASE_ANON_KEY=xxx',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Or use the run_local.bat script',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
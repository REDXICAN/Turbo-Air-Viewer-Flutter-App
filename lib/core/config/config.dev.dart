class Config {
  static const String environment = 'development';
  static const String apiUrl = 'http://localhost:8080';
  static const String firebaseProjectId = 'turboair-dev';

  // Firebase config
  static const Map<String, dynamic> firebaseConfig = {
    'apiKey': 'AIzaSyD_DEVELOPMENT_KEY',
    'authDomain': 'turboair-dev.firebaseapp.com',
    'databaseURL': 'https://turboair-dev.firebaseio.com',
    'projectId': 'turboair-dev',
    'storageBucket': 'turboair-dev.appspot.com',
    'messagingSenderId': '123456789',
    'appId': '1:123456789:web:abcdef123456',
  };

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashlytics = false;

  // Cache settings
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
}

// lib/core/config/env_config.dart
// This file loads environment variables from .env file
// NEVER hardcode sensitive values here

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Admin Credentials
  static String get adminEmail => dotenv.env['ADMIN_EMAIL'] ?? '';
  static String get adminPassword => dotenv.env['ADMIN_PASSWORD'] ?? '';
  
  // Firebase Configuration
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseDatabaseUrl => dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
  
  // Platform-specific API Keys
  static String get firebaseApiKeyWeb => dotenv.env['FIREBASE_API_KEY_WEB'] ?? '';
  static String get firebaseApiKeyAndroid => dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '';
  static String get firebaseApiKeyIos => dotenv.env['FIREBASE_API_KEY_IOS'] ?? '';
  static String get firebaseApiKeyWindows => dotenv.env['FIREBASE_API_KEY_WINDOWS'] ?? '';
  
  // Platform-specific App IDs
  static String get firebaseAppIdWeb => dotenv.env['FIREBASE_APP_ID_WEB'] ?? '';
  static String get firebaseAppIdAndroid => dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '';
  static String get firebaseAppIdIos => dotenv.env['FIREBASE_APP_ID_IOS'] ?? '';
  static String get firebaseAppIdWindows => dotenv.env['FIREBASE_APP_ID_WINDOWS'] ?? '';
  
  // Common Firebase Config
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseStorageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseMeasurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';
  
  // Email Configuration
  static String get emailSenderAddress => dotenv.env['EMAIL_SENDER_ADDRESS'] ?? '';
  static String get emailAppPassword => dotenv.env['EMAIL_APP_PASSWORD'] ?? '';
  static String get emailSenderName => dotenv.env['EMAIL_SENDER_NAME'] ?? '';
  static String get emailAppUrl => dotenv.env['EMAIL_APP_URL'] ?? '';
  
  // SMTP Configuration
  static String get smtpHost => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
  static bool get smtpSecure => dotenv.env['SMTP_SECURE'] == 'true';
  
  // Demo Account
  static String get demoPassword => dotenv.env['DEMO_PASSWORD'] ?? '';
  
  // Check if environment is properly loaded
  static bool get isLoaded => dotenv.isInitialized;
  
  // Validate required environment variables
  static bool validateConfig() {
    final missingVars = <String>[];
    
    if (adminEmail.isEmpty) missingVars.add('ADMIN_EMAIL');
    if (firebaseProjectId.isEmpty) missingVars.add('FIREBASE_PROJECT_ID');
    if (firebaseDatabaseUrl.isEmpty) missingVars.add('FIREBASE_DATABASE_URL');
    
    if (missingVars.isNotEmpty) {
      throw Exception('Missing required environment variables: ${missingVars.join(', ')}');
    }
    
    return true;
  }
}
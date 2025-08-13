#!/bin/bash
# install-flutter.sh - Install Flutter for Vercel deployment

set -e

echo "🚀 Installing Flutter for Vercel..."

# Clean up any existing Flutter installation
if [ -d "flutter" ]; then
  echo "Removing existing Flutter directory..."
  rm -rf flutter
fi

# Clone Flutter stable branch with minimal depth
echo "📦 Cloning Flutter stable branch..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Export Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

# Disable analytics and crash reporting
flutter config --no-analytics
flutter config --no-cli-animations

# Run Flutter doctor to verify installation
echo "🔍 Verifying Flutter installation..."
flutter doctor -v

# Generate firebase_options.dart if it doesn't exist
if [ ! -f "lib/firebase_options.dart" ]; then
  echo "📝 Generating firebase_options.dart from Vercel environment..."
  cat > lib/firebase_options.dart << EOF
// Auto-generated file for Vercel deployment
// DO NOT COMMIT THIS FILE
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_WEB:-}',
    appId: '${FIREBASE_APP_ID_WEB:-1:123456789:web:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    authDomain: '${FIREBASE_AUTH_DOMAIN:-turbo-air-viewer.firebaseapp.com}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_ANDROID:-}',
    appId: '${FIREBASE_APP_ID_ANDROID:-1:123456789:android:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_IOS:-}',
    appId: '${FIREBASE_APP_ID_IOS:-1:123456789:ios:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
    iosBundleId: 'com.turboair.turboAir',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_WINDOWS:-}',
    appId: '${FIREBASE_APP_ID_WINDOWS:-1:123456789:web:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    authDomain: '${FIREBASE_AUTH_DOMAIN:-turbo-air-viewer.firebaseapp.com}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );
}
EOF
  echo "✅ firebase_options.dart generated"
fi

# Get dependencies
echo "📚 Installing project dependencies..."
flutter pub get

# Create .env file if it doesn't exist (for build process)
if [ ! -f ".env" ]; then
  echo "📝 Creating .env file from Vercel environment..."
  cat > .env << EOF
# Generated from Vercel environment variables
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-temp_password}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-turbo-air-viewer}
FIREBASE_DATABASE_URL=${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}
FIREBASE_API_KEY_WEB=${FIREBASE_API_KEY_WEB:-}
FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN:-turbo-air-viewer.firebaseapp.com}
FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}
FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID:-123456789}
FIREBASE_APP_ID_WEB=${FIREBASE_APP_ID_WEB:-1:123456789:web:abcdef123456}
EMAIL_SENDER_ADDRESS=${EMAIL_SENDER_ADDRESS:-turboairquotes@gmail.com}
EMAIL_APP_PASSWORD=${EMAIL_APP_PASSWORD:-}
EOF
  echo "✅ .env file created"
fi

echo "✅ Flutter installation complete!"
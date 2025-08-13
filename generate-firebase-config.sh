#!/bin/bash
# generate-firebase-config.sh - Generate firebase_options.dart from environment variables

set -e

echo "📝 Generating firebase_options.dart from environment variables..."

# Check if required environment variables are set
if [ -z "$FIREBASE_API_KEY_WEB" ] || [ -z "$FIREBASE_PROJECT_ID" ]; then
  echo "⚠️ Warning: Firebase environment variables not set. Using defaults."
fi

# Create firebase_options.dart
cat > lib/firebase_options.dart << EOF
// File generated automatically by generate-firebase-config.sh
// DO NOT EDIT MANUALLY

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
    apiKey: '${FIREBASE_API_KEY_WEB:-AIzaSyDxLfqmJHQqRZQvBKfqQxYJe4XVKFGXFVU}',
    appId: '${FIREBASE_APP_ID_WEB:-1:123456789:web:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    authDomain: '${FIREBASE_AUTH_DOMAIN:-turbo-air-viewer.firebaseapp.com}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_ANDROID:-AIzaSyDxLfqmJHQqRZQvBKfqQxYJe4XVKFGXFVU}',
    appId: '${FIREBASE_APP_ID_ANDROID:-1:123456789:android:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_IOS:-AIzaSyDxLfqmJHQqRZQvBKfqQxYJe4XVKFGXFVU}',
    appId: '${FIREBASE_APP_ID_IOS:-1:123456789:ios:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
    iosBundleId: 'com.turboair.turboAir',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '${FIREBASE_API_KEY_WINDOWS:-AIzaSyDxLfqmJHQqRZQvBKfqQxYJe4XVKFGXFVU}',
    appId: '${FIREBASE_APP_ID_WINDOWS:-1:123456789:web:abcdef123456}',
    messagingSenderId: '${FIREBASE_MESSAGING_SENDER_ID:-123456789}',
    projectId: '${FIREBASE_PROJECT_ID:-turbo-air-viewer}',
    authDomain: '${FIREBASE_AUTH_DOMAIN:-turbo-air-viewer.firebaseapp.com}',
    databaseURL: '${FIREBASE_DATABASE_URL:-https://turbo-air-viewer-default-rtdb.firebaseio.com}',
    storageBucket: '${FIREBASE_STORAGE_BUCKET:-turbo-air-viewer.appspot.com}',
  );
}
EOF

echo "✅ firebase_options.dart generated successfully!"
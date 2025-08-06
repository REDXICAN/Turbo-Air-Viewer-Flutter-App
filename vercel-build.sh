#!/bin/bash
# This script will have access to Vercel's environment variables

# Create a temporary Dart file with the environment variables
cat > lib/core/config/env_config.dart << EOF
// AUTO-GENERATED FILE - DO NOT COMMIT
class EnvConfig {
  static const String supabaseUrl = '$SUPABASE_URL';
  static const String supabaseAnonKey = '$SUPABASE_ANON_KEY';
}
EOF

# Build Flutter web
flutter/bin/flutter build web --release --web-renderer html
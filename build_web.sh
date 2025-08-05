#!/bin/bash
# Location: Project root (same as pubspec.yaml)
# Build script for Vercel deployment

# Build Flutter web with environment variables from Vercel
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --web-renderer html
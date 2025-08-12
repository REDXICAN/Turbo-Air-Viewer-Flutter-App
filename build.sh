#!/bin/bash
# build.sh - Vercel build script for Flutter web

# Exit on error
set -e

echo "🚀 Starting Flutter Web Build for Vercel..."

# Install Flutter if not present
if [ ! -d "flutter" ]; then
  echo "📦 Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

# Run Flutter doctor
echo "🔍 Checking Flutter installation..."
flutter doctor -v

# Get dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Build for web
echo "🔨 Building Flutter web app..."
flutter build web --release --web-renderer html

echo "✅ Build complete!"
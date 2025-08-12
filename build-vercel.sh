#!/bin/bash
# build-vercel.sh - Build Flutter web app for Vercel deployment

set -e

echo "🔨 Building Flutter web application..."

# Ensure Flutter is in PATH
export PATH="$PATH:$PWD/flutter/bin"

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
  echo "❌ Flutter not found! Running install script..."
  bash install-flutter.sh
fi

# Clean any previous builds
echo "🧹 Cleaning previous build artifacts..."
flutter clean

# Get dependencies (in case they're missing)
echo "📦 Ensuring dependencies are installed..."
flutter pub get

# Build for web with optimizations
echo "🏗️ Building optimized web release..."
flutter build web --release --web-renderer html --no-tree-shake-icons

# Verify build output exists
if [ ! -d "build/web" ]; then
  echo "❌ Build failed - output directory not found!"
  exit 1
fi

# Create _redirects file for client-side routing
echo "/* /index.html 200" > build/web/_redirects

# Copy any additional files needed for production
if [ -f "vercel-public/favicon.ico" ]; then
  cp vercel-public/favicon.ico build/web/
fi

echo "✅ Build complete! Output directory: build/web"
echo "📊 Build size: $(du -sh build/web | cut -f1)"

# List contents for verification
echo "📁 Build contents:"
ls -la build/web/
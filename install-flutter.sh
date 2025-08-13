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
  echo "📝 Generating firebase_options.dart..."
  bash generate-firebase-config.sh
fi

# Get dependencies
echo "📚 Installing project dependencies..."
flutter pub get

# Create .env file if it doesn't exist (for build process)
if [ ! -f ".env" ]; then
  echo "📝 Creating .env file from example..."
  if [ -f ".env.example" ]; then
    cp .env.example .env
  else
    # Create a minimal .env file for build
    cat > .env << 'EOF'
# Minimal environment for build
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=temp_password
FIREBASE_PROJECT_ID=turbo-air-viewer
FIREBASE_DATABASE_URL=https://turbo-air-viewer-default-rtdb.firebaseio.com
EOF
  fi
fi

echo "✅ Flutter installation complete!"
#!/bin/bash

# iOS Build Fix Script
# This script fixes common iOS build issues

echo "🔧 Fixing iOS build issues..."

# Navigate to example directory
cd example

# Clean Flutter
echo "📦 Cleaning Flutter..."
flutter clean

# Remove iOS build artifacts
echo "🗑️  Removing iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# Get Flutter dependencies
echo "📥 Getting Flutter dependencies..."
flutter pub get

# Navigate to iOS directory
cd ios

# Clean CocoaPods cache
echo "🧹 Cleaning CocoaPods cache..."
pod cache clean --all

# Install pods
echo "📦 Installing CocoaPods..."
pod install

# Go back to example directory
cd ..

# Build for iOS
echo "🏗️  Building for iOS..."
flutter build ios --debug --no-codesign

echo "✅ Done! Try running: flutter run"

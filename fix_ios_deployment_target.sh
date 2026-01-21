#!/bin/bash
# Script to fix iOS deployment target for FlutterGeneratedPluginSwiftPackage
# This is a workaround for Flutter issue #162072

echo "🔧 Fixing iOS deployment target for FlutterGeneratedPluginSwiftPackage..."

PACKAGE_SWIFT_PATH="ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"

if [ -f "$PACKAGE_SWIFT_PATH" ]; then
    # Replace iOS("13.0") or iOS("XX.0") with iOS("16.0")
    sed -i '' 's/\.iOS("[0-9]*\.[0-9]*")/\.iOS("16.0")/g' "$PACKAGE_SWIFT_PATH"
    echo "✅ Updated $PACKAGE_SWIFT_PATH to iOS 16.0"
else
    echo "⚠️  $PACKAGE_SWIFT_PATH not found - run 'flutter pub get' first"
fi

echo "✅ Done!"

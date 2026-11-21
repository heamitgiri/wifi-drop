#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  WiFi Drop - Android APK Builder"
echo "========================================================"

if ! command -v flutter &> /dev/null; then
    echo "[ERROR] Flutter not found in PATH."
    exit 1
fi

echo "[1/4] Running Flutter Doctor..."
flutter doctor -v

echo "[2/4] Getting dependencies..."
flutter pub get

echo "[3/4] Running tests..."
flutter test

echo "[4/4] Building APK..."
flutter build apk --debug

APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
    echo "========================================================"
    echo "  BUILD SUCCESSFUL!"
    echo "  APK: $APK_PATH"
    shasum -a 256 "$APK_PATH"
    echo "========================================================"
else
    echo "[ERROR] APK not found at $APK_PATH"
    exit 1
fi

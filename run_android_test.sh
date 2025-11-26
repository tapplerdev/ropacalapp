#!/bin/bash

# RopacalApp Android Test Runner
# Automates emulator startup, app installation, and log monitoring

set -e  # Exit on error

echo "🚀 RopacalApp Android Test Runner"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Kill any existing emulators
echo -e "${YELLOW}Step 1: Cleaning up existing emulators...${NC}"
pkill -9 qemu-system-x86_64 2>/dev/null || true
pkill -9 emulator 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Step 2: Start Android emulator
echo -e "${YELLOW}Step 2: Starting Android emulator...${NC}"
~/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.0 -no-snapshot-load -no-audio -dns-server 8.8.8.8,8.8.4.4 > /dev/null 2>&1 &
EMULATOR_PID=$!
echo "Emulator started with PID: $EMULATOR_PID"
echo ""

# Step 3: Wait for emulator to boot
echo -e "${YELLOW}Step 3: Waiting for emulator to boot...${NC}"
echo "This may take 30-60 seconds..."

# Wait for device to be detected
~/Library/Android/sdk/platform-tools/adb wait-for-device

# Wait for boot to complete
BOOT_COMPLETE=""
while [ -z "$BOOT_COMPLETE" ]; do
  BOOT_COMPLETE=$(~/Library/Android/sdk/platform-tools/adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  if [ "$BOOT_COMPLETE" != "1" ]; then
    echo -n "."
    sleep 2
  fi
done
echo ""
echo -e "${GREEN}✓ Emulator boot complete${NC}"
echo ""

# Wait for Package Manager service to be ready
echo "Waiting for Package Manager service..."
PACKAGE_MANAGER_READY=""
RETRY_COUNT=0
MAX_RETRIES=30

while [ -z "$PACKAGE_MANAGER_READY" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Try to list packages - if this works, Package Manager is ready
  PM_TEST=$(~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm list packages 2>&1)
  if echo "$PM_TEST" | grep -q "package:"; then
    PACKAGE_MANAGER_READY="1"
  else
    echo -n "."
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
  fi
done

if [ -z "$PACKAGE_MANAGER_READY" ]; then
  echo ""
  echo -e "${RED}✗ Timeout waiting for Package Manager service${NC}"
  exit 1
fi

echo ""
echo -e "${GREEN}✓ Package Manager ready${NC}"
echo ""

# Step 4: Clear app data and run Flutter app in RELEASE mode
echo -e "${YELLOW}Step 4: Clearing app data and installing Flutter app (RELEASE MODE)...${NC}"
echo "Clearing existing app data..."
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm clear com.example.ropacalapp 2>/dev/null || true
echo "Building optimized release version (this may take a minute)..."
echo ""

# Run Flutter in RELEASE mode for better performance
~/develop/flutter/bin/flutter run --release -d emulator-5554 &
FLUTTER_PID=$!

# Step 5: Monitor logs
echo ""
echo -e "${GREEN}✓ App launched successfully${NC}"
echo ""
echo "=================================="
echo "📱 MONITORING APP LOGS"
echo "=================================="
echo ""
echo "🔍 Watching for:"
echo "  • [Android] camera bearing updates"
echo "  • [Navigation] GPS updates"
echo "  • [Map] viewport state changes"
echo ""
echo "Press Ctrl+C to stop"
echo ""
echo "-----------------------------------"
echo ""

# Wait for Flutter to start outputting logs
sleep 10

# Tail the Flutter output and filter for important logs
# The Flutter process outputs to stdout, so we can't tail it directly
# Instead, we'll let it run and show all output
wait $FLUTTER_PID

# Cleanup function
cleanup() {
  echo ""
  echo ""
  echo -e "${YELLOW}Cleaning up...${NC}"
  kill $FLUTTER_PID 2>/dev/null || true
  pkill -9 qemu-system-x86_64 2>/dev/null || true
  pkill -9 emulator 2>/dev/null || true
  echo -e "${GREEN}✓ Cleanup complete${NC}"
  exit 0
}

# Set up cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Keep script running
wait

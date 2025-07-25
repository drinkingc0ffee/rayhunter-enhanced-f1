#!/bin/bash

# QR Code Test App Installer Script
# This script builds, installs, and runs the test_qr application on the Orbic device

echo "🎯 QR Code Test App Installer"
echo "=============================="

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ Error: adb not found. Please install Android Debug Bridge (adb)"
    exit 1
fi

# Check if device is connected
echo "📱 Checking device connection..."
if ! adb devices | grep -q "device$"; then
    echo "❌ Error: No device connected or device not authorized"
    echo "   Please connect your device and ensure USB debugging is enabled"
    exit 1
fi

echo "✅ Device connected"

# Build the test_qr binary using Docker
echo "🔨 Building test_qr binary for ARM..."
if ! ./docker_make.sh; then
    echo "❌ Error: Failed to build test_qr binary"
    exit 1
fi

echo "✅ Build successful"

# Check if binary exists
BINARY_PATH="daemon/target/armv7-unknown-linux-gnueabihf/release/test_qr"
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: test_qr binary not found at $BINARY_PATH"
    exit 1
fi

# Install to device
echo "📱 Installing test_qr to device..."
if ! adb push "$BINARY_PATH" /tmp/test_qr; then
    echo "❌ Error: Failed to push binary to device"
    exit 1
fi

echo "🔧 Setting executable permissions..."
if ! adb shell "chmod +x /tmp/test_qr"; then
    echo "❌ Error: Failed to set executable permissions"
    exit 1
fi

echo "✅ Installation complete"

# Check if test_qr is already running
echo "🔍 Checking if test_qr is already running..."
if adb shell "ps aux | grep -v grep | grep test_qr" | grep -q test_qr; then
    echo "⚠️  test_qr is already running. Stopping existing instance..."
    adb shell "pkill test_qr" 2>/dev/null || true
    sleep 1
fi

# Start the application
echo "🚀 Starting test_qr application..."
echo ""
echo "📋 Usage Instructions:"
echo "   • Quick press button → Display QR code for 10 seconds"
echo "   • Triple quick press → Exit application"
echo ""
echo "🔗 QR Code links to: https://eff.org"
echo ""
echo "📺 Starting application in background..."

# Run in background and show initial output
adb shell "/bin/rootshell -c '/tmp/test_qr'" &
APP_PID=$!

# Give it a moment to start
sleep 2

# Check if it's running
if adb shell "ps aux | grep -v grep | grep test_qr" | grep -q test_qr; then
    echo "✅ test_qr is now running in background"
    echo ""
    echo "🎯 Ready! Press the button on your device to display the QR code."
    echo ""
    echo "💡 Tips:"
    echo "   • Make sure the display is on before pressing the button"
    echo "   • Use quick presses (don't hold the button down)"
    echo "   • The QR code will display for exactly 10 seconds"
    echo ""
    echo "🛑 To stop the application later, run:"
    echo "   adb shell \"pkill test_qr\""
else
    echo "❌ Error: test_qr failed to start"
    echo "📋 Troubleshooting:"
    echo "   • Make sure device has root access via /bin/rootshell"
    echo "   • Check if /dev/input/event0 exists on the device"
    echo "   • Verify framebuffer /dev/fb0 is accessible"
    exit 1
fi

echo ""
echo "🎉 Installation and startup complete!" 
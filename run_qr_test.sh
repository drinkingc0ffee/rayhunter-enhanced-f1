#!/bin/bash

echo "🚀 Starting Enhanced QR Code Test App"
echo "======================================"
echo ""
echo "This app uses /dev/input/event1 (menu button) to avoid device power management interference."
echo "Long press the menu button for 2 seconds to display QR code for https://eff.org"
echo ""
echo "Features:"
echo "- Uses /dev/input/event1 (menu button) instead of power button"
echo "- 2-second long press detection"
echo "- 10-second QR code display with automatic clearing"
echo "- Continuous background operation"
echo "- No interference with device power management"
echo ""

# Kill any existing test_qr process
echo "🔄 Stopping any existing test_qr processes..."
adb shell "/bin/rootshell -c 'pkill -f test_qr' 2>/dev/null || true"

# Start the enhanced test_qr app
echo "🎯 Starting enhanced test_qr app with event1 long press..."
adb shell "/bin/rootshell /tmp/test_qr" 
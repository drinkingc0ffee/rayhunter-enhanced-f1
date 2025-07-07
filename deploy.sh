#!/bin/bash -e

# Deployment script for rayhunter-enhanced
# This script deploys the built binaries to the connected device

echo "🚀 Deploying rayhunter-enhanced to device..."
echo "===============================================\n"

# Check if device is connected
echo "🔍 Checking device connection..."
if ! adb devices | grep -q "device$"; then
    echo "❌ No device connected. Please connect your device and enable USB debugging."
    exit 1
fi

DEVICE_ID=$(adb devices | grep "device$" | cut -f1)
echo "✅ Device connected: $DEVICE_ID\n"

# Stop existing daemon
echo "🛑 Stopping existing rayhunter daemon..."
adb shell '/bin/rootshell -c "/etc/init.d/rayhunter_daemon stop"' || echo "⚠️  Daemon not running or failed to stop"
echo "✅ Daemon stopped\n"

# Create directories
echo "📁 Creating directories on device..."
adb shell '/bin/rootshell -c "mkdir -p /data/rayhunter/gps-data"'
adb shell '/bin/rootshell -c "mkdir -p /data/rayhunter/web"'
echo "✅ Directories created\n"

# Deploy binaries
echo "📦 Deploying rayhunter-daemon..."
adb push target/armv7-unknown-linux-musleabihf/firmware/rayhunter-daemon /data/rayhunter/rayhunter-daemon
adb shell '/bin/rootshell -c "chmod +x /data/rayhunter/rayhunter-daemon"'
echo "✅ Rayhunter-daemon deployed\n"

# Deploy web interface
echo "📦 Deploying web interface..."
adb push bin/web/build /data/rayhunter/web
echo "✅ Web interface deployed\n"

# Optional: Deploy additional utilities
if [ -f "target/armv7-unknown-linux-musleabihf/firmware/rayhunter-check" ]; then
    echo "📦 Deploying rayhunter-check..."
    adb push target/armv7-unknown-linux-musleabihf/firmware/rayhunter-check /data/rayhunter/rayhunter-check || echo "⚠️  Failed to deploy rayhunter-check"
    adb shell '/bin/rootshell -c "chmod +x /data/rayhunter/rayhunter-check"' || echo "⚠️  Failed to set permissions"
    echo "✅ Rayhunter-check deployed\n"
fi

# Reboot device
echo "🔄 Rebooting device to complete installation..."
adb shell '/bin/rootshell -c "reboot"'
echo "✅ Device reboot initiated\n"

echo "⏳ Waiting for device to come back online..."
sleep 15

# Wait for device to be ready
echo "🔍 Waiting for device connection..."
for i in {1..30}; do
    if adb devices | grep -q "device$"; then
        echo "✅ Device is back online\n"
        break
    fi
    sleep 2
    echo "⏳ Still waiting... ($i/30)"
done

# Start daemon
echo "🚀 Starting rayhunter daemon..."
adb shell '/bin/rootshell -c "/etc/init.d/rayhunter_daemon start"'
echo "✅ Rayhunter daemon started\n"

# Get device IP
echo "🌐 Getting device IP address..."
DEVICE_IP=$(adb shell '/bin/rootshell -c "ip addr show bridge0 | grep \"inet \" | cut -d\" \" -f6 | cut -d\"/\" -f1"' | tr -d '\r')
echo "✅ Device IP: $DEVICE_IP\n"

echo "🎉 Deployment completed successfully!"
echo "==============================================="
echo "📱 Device: $DEVICE_ID"
echo "🌐 Web Interface: http://$DEVICE_IP:8080"
echo "📊 Check status: adb shell '/bin/rootshell -c \"ps | grep rayhunter\"'"
echo "📝 View logs: adb shell '/bin/rootshell -c \"tail -f /data/rayhunter/rayhunter.log\"'" 
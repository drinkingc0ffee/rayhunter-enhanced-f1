#!/bin/bash

# Restart Docker container with proper USB device access
# This script will restart the rayhunter container with better USB support

set -e

CONTAINER_NAME="540758e8fd72"
NEW_CONTAINER_NAME="rayhunter-build-docker-usb"

echo "🔧 Restarting Docker container with USB device access..."
echo "========================================================"

# Stop and remove the current container
echo "🛑 Stopping current container..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

# Create new container with enhanced USB access
echo "🐳 Creating new container with USB access..."
docker run -d \
    --name "$NEW_CONTAINER_NAME" \
    --hostname rayhunter-build \
    -p 8081:8080 \
    -p 3001:3000 \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /dev:/dev \
    --device-cgroup-rule='c 189:* rmw' \
    --device-cgroup-rule='c 189:* rwm' \
    --cap-add=SYS_RAWIO \
    --cap-add=SYS_ADMIN \
    --privileged \
    ubuntu:22.04 \
    tail -f /dev/null

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Copy all files from the old container to the new one
echo "📁 Copying project files..."
docker cp /Users/beisenmann/rayhunter-enhanced/. "$NEW_CONTAINER_NAME:/home/rayhunter/"

# Install essential packages
echo "📦 Installing essential packages..."
docker exec "$NEW_CONTAINER_NAME" bash -c "
    apt-get update && apt-get install -y \
    curl wget git build-essential pkg-config \
    software-properties-common ca-certificates \
    gnupg lsb-release sudo vim nano htop tree \
    unzip zip usbutils android-tools-adb \
    android-tools-fastboot udev \
    && rm -rf /var/lib/apt/lists/*
"

# Create rayhunter user
echo "👤 Setting up rayhunter user..."
docker exec "$NEW_CONTAINER_NAME" bash -c "
    useradd -m -s /bin/bash rayhunter || true
    usermod -aG sudo rayhunter
    echo 'rayhunter ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/rayhunter
    mkdir -p /home/rayhunter
    chown -R rayhunter:rayhunter /home/rayhunter
    chmod +x /home/rayhunter/*.sh
"

# Test USB access
echo "🧪 Testing USB access..."
docker exec "$NEW_CONTAINER_NAME" bash -c "
    echo 'USB devices in container:'
    lsusb
    echo ''
    echo 'USB device permissions:'
    ls -la /dev/bus/usb/
    echo ''
    echo 'Testing ADB:'
    adb version
"

echo ""
echo "✅ Container restarted with USB access!"
echo "======================================="
echo "🐳 New container name: $NEW_CONTAINER_NAME"
echo "📱 To test ADB connection:"
echo "   docker exec -it $NEW_CONTAINER_NAME bash"
echo "   adb devices"
echo ""
echo "🔧 To run the build:"
echo "   docker exec -it $NEW_CONTAINER_NAME bash"
echo "   cd /home/rayhunter"
echo "   ./setup_ubuntu_ci.sh"
echo "   ./build_all.sh" 
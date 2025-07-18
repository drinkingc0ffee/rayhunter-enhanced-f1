#!/bin/bash -e

# ARM Cross-Compilation Toolchain Setup for Ubuntu Docker
# This script installs and configures the ARM toolchain needed for rayhunter-enhanced

echo "🔧 Setting up ARM Cross-Compilation Toolchain..."
echo "================================================"

# Update package list
echo "📦 Updating package list..."
apt-get update

# Install essential build tools
echo "🔨 Installing essential build tools..."
apt-get install -y \
    build-essential \
    cmake \
    pkg-config \
    curl \
    wget \
    git \
    unzip \
    software-properties-common

# Add the ARM toolchain repository
echo "📚 Adding ARM toolchain repository..."
add-apt-repository -y ppa:ubuntu-toolchain-r/test

# Update again after adding repository
apt-get update

# Install ARM cross-compilation toolchain
echo "🔧 Installing ARM cross-compilation toolchain..."
apt-get install -y \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    libstdc++6-armhf-cross

# Install musl toolchain for static linking
echo "🔧 Installing musl toolchain..."
apt-get install -y \
    musl-tools \
    musl-dev

# Install additional dependencies
echo "📦 Installing additional dependencies..."
apt-get install -y \
    libssl-dev \
    libudev-dev \
    libusb-1.0-0-dev \
    libpcap-dev \
    libasound2-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libgtk-3-dev \
    libwebkit2gtk-4.0-dev \
    libappindicator3-dev \
    librsvg2-dev \
    libnotify-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 \
    gstreamer1.0-pulseaudio

# Install Node.js and npm
echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Install Android SDK and ADB
echo "📱 Installing Android SDK and ADB..."
apt-get install -y \
    android-tools-adb \
    android-tools-fastboot

# Install Rust
echo "🦀 Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Add ARM targets to Rust
echo "🎯 Adding ARM targets to Rust..."
rustup target add armv7-unknown-linux-musleabihf
rustup target add armv7-unknown-linux-gnueabihf

# Create build environment file
echo "📝 Creating build environment file..."
cat > ~/.rayhunter_build_env << 'EOF'
# Rayhunter Build Environment
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="/usr/bin:/bin:$PATH"

# ARM Cross-compilation variables
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_AR=arm-linux-gnueabihf-ar

export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_AR=arm-linux-gnueabihf-ar

# Host compiler variables
export CC_x86_64_unknown_linux_gnu=gcc
export CXX_x86_64_unknown_linux_gnu=g++
export AR_x86_64_unknown_linux_gnu=ar
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc

# Unset global compiler variables to avoid conflicts
unset CC CXX AR LD CFLAGS CXXFLAGS LDFLAGS LINK
unset CARGO_TARGET_CC CARGO_TARGET_CXX CARGO_TARGET_AR CARGO_TARGET_LINKER
EOF

# Test the toolchain
echo "🧪 Testing ARM toolchain..."
source ~/.rayhunter_build_env

# Test ARM compiler
if ! arm-linux-gnueabihf-gcc --version > /dev/null 2>&1; then
    echo "❌ ARM compiler test failed"
    exit 1
fi

# Test Rust ARM target
if ! cargo check --target armv7-unknown-linux-musleabihf --quiet 2>/dev/null; then
    echo "❌ Rust ARM target test failed"
    exit 1
fi

echo "✅ ARM toolchain setup completed successfully!"
echo ""
echo "📋 Installed components:"
echo "   - ARM GCC toolchain (arm-linux-gnueabihf-gcc)"
echo "   - Rust with ARM targets"
echo "   - Node.js and npm"
echo "   - Android SDK and ADB"
echo "   - Build dependencies"
echo ""
echo "🚀 You can now run: ./build_and_deploy.sh" 
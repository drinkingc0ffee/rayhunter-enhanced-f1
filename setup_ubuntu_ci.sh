#!/bin/bash -e

# Ubuntu CI/CD Build Environment Setup Script for rayhunter-enhanced
# Step 1: Install all toolchains and dependencies

echo "🔧 Setting up Ubuntu build environment for rayhunter-enhanced..."
echo "================================================================="
echo "📋 This script will install:"
echo "  - Rust toolchain with ARM targets"
echo "  - Node.js and npm"
echo "  - Android SDK and adb"
echo "  - ARM cross-compilation tools"
echo "  - Build dependencies"
echo ""

# Check if running as root for system package installation
if [ "$EUID" -eq 0 ]; then
    echo "🔑 Running as root - will install system packages"
    SUDO_CMD=""
else
    echo "👤 Running as regular user - using sudo for system packages"
    SUDO_CMD="sudo"
fi

# FIRST: Update package lists to ensure we have the latest package information
echo "📦 Updating package lists (this may take a moment)..."
$SUDO_CMD apt update && echo "✅ Package lists updated"

# Install basic build dependencies
echo "📦 Installing basic build dependencies..."
$SUDO_CMD apt install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    ca-certificates \
    gnupg \
    lsb-release \
    file

# Install ARM cross-compilation tools
echo "📦 Installing ARM cross-compilation tools..."
$SUDO_CMD apt install -y \
    libc6-armhf-cross \
    libc6-dev-armhf-cross \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf

# Install Rust if not already installed
if ! command -v rustc &> /dev/null; then
    echo "🦀 Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source ~/.cargo/env
    echo "✅ Rust installed"
else
    echo "ℹ️  Rust is already installed"
    source ~/.cargo/env
    rustup update stable
    echo "✅ Rust updated to latest stable"
fi

# Install Rust components and ARM targets
echo "📦 Installing Rust components and ARM targets..."
source ~/.cargo/env
rustup component add rustfmt clippy
rustup target add armv7-unknown-linux-musleabihf
rustup target add armv7-unknown-linux-gnueabihf

# Install Node.js and npm
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO_CMD -E bash -
    $SUDO_CMD apt install -y nodejs
    echo "✅ Node.js and npm installed"
else
    echo "ℹ️  Node.js is already installed"
fi

# Install Android Debug Bridge (adb)
echo "📱 Installing Android Debug Bridge (adb)..."
$SUDO_CMD apt install -y android-tools-adb android-tools-fastboot
echo "✅ adb installed"

# Verify ARM cross-compiler installation
echo "🔍 Verifying ARM cross-compiler installation..."
if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "❌ ARM cross-compiler not found in PATH"
    echo "🔧 Adding common ARM cross-compiler paths to PATH..."
    # Add common ARM cross-compiler paths
    export PATH="/usr/arm-linux-gnueabihf/bin:$PATH"
    export PATH="/usr/bin:$PATH"
    if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
        echo "❌ ARM cross-compiler still not found. Please check installation."
        exit 1
    fi
fi
echo "✅ ARM cross-compiler found: $(which arm-linux-gnueabihf-gcc)"

# Set up ARM cross-compilation environment variables
echo "📦 Setting up ARM cross-compilation environment..."
cat > ~/.rayhunter_build_env << 'EOF'
#!/bin/bash
# Rayhunter Enhanced Build Environment

# Rust environment
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.cargo/env

# Ensure ARM cross-compiler is in PATH
export PATH="/usr/arm-linux-gnueabihf/bin:/usr/bin:$PATH"

# ARM cross-compilation environment variables (target-specific only)
# This allows build scripts to compile for host architecture while targets compile for ARM
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_AR=arm-linux-gnueabihf-ar

export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_AR=arm-linux-gnueabihf-ar

echo "✅ Rayhunter build environment loaded"
EOF

chmod +x ~/.rayhunter_build_env

# Add to bashrc if not already there
if ! grep -q "rayhunter_build_env" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Rayhunter Enhanced build environment" >> ~/.bashrc
    echo "source ~/.rayhunter_build_env" >> ~/.bashrc
    echo "✅ Build environment added to ~/.bashrc"
fi

# Source the environment
source ~/.rayhunter_build_env

# Verify installations
echo ""
echo "🔍 Verifying installations..."
echo "============================="
echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "gcc: $(gcc --version | head -n1)"
if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "ARM GCC: $(arm-linux-gnueabihf-gcc --version | head -n1)"
    echo "ARM GCC Path: $(which arm-linux-gnueabihf-gcc)"
else
    echo "❌ ARM GCC: NOT FOUND"
    echo "🔧 Attempting to fix ARM cross-compiler installation..."
    $SUDO_CMD apt install -y --reinstall gcc-arm-linux-gnueabihf
    if command -v arm-linux-gnueabihf-gcc &> /dev/null; then
        echo "✅ ARM GCC fixed: $(arm-linux-gnueabihf-gcc --version | head -n1)"
    else
        echo "❌ ARM GCC still not working. Manual intervention required."
    fi
fi
echo "adb: $(adb --version | head -n1)"

echo ""
echo "ARM Targets:"
echo "============"
rustup target list --installed | grep armv7

echo ""
echo "🧪 Testing ARM cross-compiler..."
echo "================================"
# Create a simple test program
cat > /tmp/test_arm_compile.c << 'EOF'
#include <stdio.h>
int main() {
    printf("ARM cross-compiler test\n");
    return 0;
}
EOF

# Test ARM cross-compilation
if arm-linux-gnueabihf-gcc -o /tmp/test_arm_compile /tmp/test_arm_compile.c 2>/dev/null; then
    echo "✅ ARM cross-compiler test successful"
    file /tmp/test_arm_compile
    rm -f /tmp/test_arm_compile /tmp/test_arm_compile.c
else
    echo "❌ ARM cross-compiler test failed"
    echo "🔧 Attempting to fix cross-compiler libraries..."
    $SUDO_CMD apt install -y --reinstall libc6-dev-armhf-cross libc6-armhf-cross
    if arm-linux-gnueabihf-gcc -o /tmp/test_arm_compile /tmp/test_arm_compile.c 2>/dev/null; then
        echo "✅ ARM cross-compiler test successful after fix"
        file /tmp/test_arm_compile
        rm -f /tmp/test_arm_compile /tmp/test_arm_compile.c
    else
        echo "❌ ARM cross-compiler test still failing"
        echo "⚠️  Build may fail - manual intervention required"
    fi
fi

echo ""
echo "✅ Ubuntu build environment setup completed successfully!"
echo "========================================================="
echo ""
echo "🎯 Next steps:"
echo "1. Run: ./fetch_source.sh (to download source code)"
echo "2. Run: ./build_and_deploy.sh (to build and install)"
echo "" 
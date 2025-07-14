#!/bin/bash -e

# Quick build script for rayhunter-enhanced
# This script builds all components for ARM targets

echo "🔨 Building rayhunter-enhanced (ARM targets)..."
echo "==============================================="

# Source build environment (local deps first, then system)
if [ -f "./build_deps/setup-env.sh" ]; then
    source "./build_deps/setup-env.sh"
    echo "✅ Local build environment loaded"
elif [ -f ~/.cargo/env ]; then
    source ~/.cargo/env
    echo "✅ System Rust environment loaded"
elif [ -f ~/.rayhunter_build_env ]; then
    source ~/.rayhunter_build_env
    echo "✅ Rayhunter build environment loaded"
else
    echo "⚠️  No build environment found!"
    echo "   Run ./setup_local_deps.sh for local install, or"
    echo "   Run ./setup_ubuntu_ci.sh for CI install"
    exit 1
fi

# CRITICAL: Clean environment and fix PATH for proper cross-compilation
# Remove any ARM cross-compiler paths from the beginning of PATH
# This ensures that 'cc' resolves to the host compiler, not ARM compiler
export PATH=$(echo "$PATH" | sed 's|/usr/arm-linux-gnueabihf/bin:||g')

# Ensure system binaries come first
export PATH="/usr/bin:/bin:$PATH"

# CRITICAL: Unset all global compiler variables that might interfere with build scripts
unset CC CXX AR LD CFLAGS CXXFLAGS LDFLAGS LINK
unset CARGO_TARGET_CC CARGO_TARGET_CXX CARGO_TARGET_AR CARGO_TARGET_LINKER

# Set ONLY target-specific variables for ARM cross-compilation
# This ensures build scripts compile for host while targets compile for ARM
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_AR=arm-linux-gnueabihf-ar

export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_AR=arm-linux-gnueabihf-ar

# Explicitly set host compiler variables for build scripts
export CC_x86_64_unknown_linux_gnu=gcc
export CXX_x86_64_unknown_linux_gnu=g++
export AR_x86_64_unknown_linux_gnu=ar
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc

# Verify compiler availability
if ! command -v gcc &> /dev/null; then
    echo "❌ Host compiler 'gcc' not found"
    exit 1
fi

if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "❌ ARM cross-compiler 'arm-linux-gnueabihf-gcc' not found"
    exit 1
fi

echo "✅ Cross-compilation environment configured"

# Build with firmware profile for all ARM targets
echo "🔧 Building Rust binaries..."
cargo build --profile firmware --target armv7-unknown-linux-musleabihf

# Build web frontend
echo "📦 Building web frontend..."
cd bin/web
npm ci --silent --audit=false 2>/dev/null || npm install --silent --audit=false
npm run build --silent
cd ../..

echo "✅ Build complete!"
echo "📁 ARM binaries: target/armv7-unknown-linux-musleabihf/firmware/"
echo "📁 Web files: bin/web/build/"

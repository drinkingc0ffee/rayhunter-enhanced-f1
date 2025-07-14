#!/bin/bash -e

# Comprehensive build script for rayhunter-enhanced
# This script builds all components in the correct order with proper cross-compilation

echo "🏗️  Building rayhunter-enhanced..."
echo "=====================================\n"

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

# Verify compiler availability and correct resolution
if ! command -v gcc &> /dev/null; then
    echo "❌ Host compiler 'gcc' not found"
    exit 1
fi

if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "❌ ARM cross-compiler 'arm-linux-gnueabihf-gcc' not found"
    exit 1
fi

echo "✅ Cross-compilation environment configured"
echo "   Host compiler (build scripts): $(which gcc)"
echo "   ARM compiler (targets): $(which arm-linux-gnueabihf-gcc)"

# CRITICAL: Verify that 'cc' resolves to the host compiler, not ARM compiler
CC_RESOLVED=$(which cc 2>/dev/null || echo "")
if [ -n "$CC_RESOLVED" ]; then
    echo "   System cc command: $CC_RESOLVED"
    # Test that it's the host compiler
    if $CC_RESOLVED --version 2>&1 | grep -q "arm-linux-gnueabihf"; then
        echo "❌ ERROR: 'cc' is resolving to ARM compiler instead of host compiler"
        echo "   This will cause build script failures"
        exit 1
    fi
else
    echo "   System cc command: (not found - using gcc)"
fi

# Test cross-compilation setup with a simple build
echo "🧪 Testing cross-compilation setup..."
if ! cargo check --target armv7-unknown-linux-musleabihf -p rayhunter --quiet 2>/dev/null; then
    echo "❌ Cross-compilation test failed"
    echo "   This usually means the ARM toolchain is not properly configured"
    exit 1
fi
echo "✅ Cross-compilation test passed"
echo ""

# Build web frontend first
echo "📦 Building web frontend..."
cd bin/web

# Clean install to avoid audit warnings during build
echo "  📦 Installing dependencies..."
npm ci --silent --audit=false 2>/dev/null || npm install --silent --audit=false

echo "  🔨 Building web assets..."
npm run build --silent

cd ../..
echo "✅ Web frontend built successfully\n"

# Build library and core binaries with proper target specification
echo "🔧 Building core library..."
cargo build --release --target armv7-unknown-linux-musleabihf -p rayhunter
echo "✅ Core library built successfully\n"

echo "🔧 Building telcom-parser..."
cargo build --release --target armv7-unknown-linux-musleabihf -p telcom-parser
echo "✅ Telcom-parser built successfully\n"

# Build firmware binaries
echo "🔧 Building rootshell (firmware profile)..."
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p rootshell
echo "✅ Rootshell built successfully\n"

echo "🔧 Building rayhunter-daemon (firmware profile)..."
cargo build --profile firmware --target armv7-unknown-linux-musleabihf --bin rayhunter-daemon
echo "✅ Rayhunter-daemon built successfully\n"

echo "🔧 Building rayhunter-check (firmware profile)..."
cargo build --profile firmware --target armv7-unknown-linux-musleabihf --bin rayhunter-check
echo "✅ Rayhunter-check built successfully\n"

# Build installer (depends on firmware binaries)
echo "🔧 Building installer..."
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p installer
echo "✅ Installer built successfully\n"

echo "🎉 All components built successfully!"
echo "=====================================\n"
echo "📁 ARM binaries location: target/armv7-unknown-linux-musleabihf/firmware/"
echo "📁 Web files location: bin/web/build/"
echo ""
echo "🚀 To deploy to device, run: ./deploy.sh" 
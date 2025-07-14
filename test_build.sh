#!/bin/bash

# Test script for rayhunter-enhanced build environment
# Verifies all dependencies and configurations before building

echo "🧪 Testing rayhunter-enhanced build environment..."
echo "=================================================="

# Test 0: Check if we need to update package lists (Ubuntu/Debian systems)
if command -v apt &> /dev/null; then
    echo "🔍 Pre-Test: Checking package manager..."
    
    # Check if we're in a system that hasn't been updated recently
    if [ -f /var/cache/apt/pkgcache.bin ]; then
        # Check if package cache is older than 1 day
        if [ $(find /var/cache/apt/pkgcache.bin -mtime +1 -print) ]; then
            echo "⚠️  Package cache is old - consider running 'sudo apt update' first"
        else
            echo "✅ Package cache is recent"
        fi
    else
        echo "ℹ️  No package cache found - system may need 'sudo apt update'"
    fi
fi

# Test 1: Check build environment
echo ""
echo "🔍 Test 1: Checking build environment..."
BUILD_ENV_FOUND=false

if [ -f "./build_deps/setup-env.sh" ]; then
    source "./build_deps/setup-env.sh"
    echo "✅ Local build environment found"
    BUILD_ENV_FOUND=true
elif [ -f ~/.cargo/env ]; then
    source ~/.cargo/env
    echo "✅ System Rust environment found"
    BUILD_ENV_FOUND=true
elif [ -f ~/.rayhunter_build_env ]; then
    source ~/.rayhunter_build_env
    echo "✅ Rayhunter build environment found"
    BUILD_ENV_FOUND=true
fi

if [ "$BUILD_ENV_FOUND" = false ]; then
    echo "❌ No build environment found"
    echo "ℹ️  Available setup options:"
    echo "  - ./setup_local_deps.sh (recommended - no root needed)"
    echo "  - ./setup_ubuntu_ci.sh (system-wide installation)"
    echo "  - ./setup_ubuntu_build_env.sh (interactive setup)"
    exit 1
fi

# Test 2: Check required tools
echo ""
echo "🔍 Test 2: Checking required tools..."

# Check Rust
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust not found"
    exit 1
fi
echo "✅ Rust: $(rustc --version)"

# Check Cargo
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found"
    exit 1
fi
echo "✅ Cargo: $(cargo --version)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found"
    exit 1
fi
echo "✅ Node.js: $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found"
    exit 1
fi
echo "✅ npm: $(npm --version)"

# Check host compiler
if ! command -v gcc &> /dev/null; then
    echo "❌ Host compiler (gcc) not found"
    exit 1
fi
echo "✅ Host compiler: $(gcc --version | head -n1)"

# Check ARM cross-compiler
if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
    echo "❌ ARM cross-compiler not found"
    exit 1
fi
echo "✅ ARM cross-compiler: $(arm-linux-gnueabihf-gcc --version | head -n1)"

# Test 3: Check Rust targets
echo ""
echo "🔍 Test 3: Checking Rust targets..."
if ! rustup target list --installed | grep -q "armv7-unknown-linux-musleabihf"; then
    echo "❌ ARM target not installed"
    exit 1
fi
echo "✅ ARM target installed"

# Test 4: Test cross-compilation
echo ""
echo "🔍 Test 4: Testing cross-compilation..."
if ! cargo check --target armv7-unknown-linux-musleabihf -p rayhunter --quiet 2>/dev/null; then
    echo "❌ Cross-compilation test failed"
    echo "   Attempting to diagnose the issue..."
    
    # Try to get more detailed error info
    echo "   Running detailed check..."
    cargo check --target armv7-unknown-linux-musleabihf -p rayhunter 2>&1 | head -20
    exit 1
fi
echo "✅ Cross-compilation test passed"

# Test 5: Test web build dependencies
echo ""
echo "🔍 Test 5: Testing web build dependencies..."
cd bin/web
if ! npm install --silent --audit=false 2>/dev/null; then
    echo "❌ Web dependencies installation failed"
    exit 1
fi
echo "✅ Web dependencies installed"

# Test simple web build
if ! npm run build --silent 2>/dev/null; then
    echo "❌ Web build test failed"
    exit 1
fi
echo "✅ Web build test passed"
cd ../..

echo ""
echo "🎉 All tests passed!"
echo "   Build environment is ready"
echo "   Run ./build_all.sh to build the project" 
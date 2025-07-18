#!/bin/bash -e

# Build rayhunter-enhanced for host architecture (simpler alternative)
# This script builds the application for the current system instead of ARM

echo "🔨 Building rayhunter-enhanced for host architecture..."
echo "======================================================"

# Configuration
SOURCE_DIR="$HOME/rayhunter-enhanced"
BUILD_PROFILE="${BUILD_PROFILE:-release}"

echo "📋 Build configuration:"
echo "  Source directory: $SOURCE_DIR"
echo "  Build profile: $BUILD_PROFILE"
echo "  Target: host architecture"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Change to source directory
cd "$SOURCE_DIR"

# Load build environment
echo "🔧 Loading build environment..."
if [ -f "$HOME/.cargo/env" ]; then
    source ~/.cargo/env
    echo "✅ Rust environment loaded"
else
    echo "⚠️  Rust environment not found"
fi

# Check for build dependencies
echo ""
echo "🔍 Checking build dependencies..."

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please install Rust first."
    echo "   Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi
echo "✅ Rust/Cargo: $(cargo --version)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    echo "   Run: curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs"
    exit 1
fi
echo "✅ Node.js: $(node --version)"

# Build the project
echo ""
echo "🔨 Building rayhunter-enhanced..."
echo "================================"

# Clean previous builds if requested
if [ "${CLEAN_BUILD:-false}" = "true" ]; then
    echo "🧹 Cleaning previous builds..."
    cargo clean
    [ -d "bin/web/node_modules" ] && rm -rf bin/web/node_modules
    [ -d "bin/web/build" ] && rm -rf bin/web/build
    echo "✅ Clean completed"
fi

# Build web frontend first
echo "📦 Building web frontend..."
cd bin/web

# Install dependencies
echo "  📦 Installing dependencies..."
npm ci --silent --audit=false 2>/dev/null || npm install --silent --audit=false

# Build web assets
echo "  🔨 Building web assets..."
npm run build --silent

cd ../..
echo "✅ Web frontend built successfully"

# Build Rust components for host architecture
echo ""
echo "🔧 Building Rust components for host architecture..."

# Build library
echo "📦 Building core library..."
cargo build --$BUILD_PROFILE -p rayhunter
echo "✅ Core library built successfully"

# Build telcom-parser
echo "📦 Building telcom-parser..."
cargo build --$BUILD_PROFILE -p telcom-parser
echo "✅ Telcom-parser built successfully"

# Build binaries
echo "📦 Building rayhunter-daemon..."
cargo build --$BUILD_PROFILE --bin rayhunter-daemon
echo "✅ Rayhunter-daemon built successfully"

echo "📦 Building rayhunter-check..."
cargo build --$BUILD_PROFILE --bin rayhunter-check
echo "✅ Rayhunter-check built successfully"

echo "📦 Building rootshell..."
cargo build --$BUILD_PROFILE -p rootshell
echo "✅ Rootshell built successfully"

echo "📦 Building installer..."
cargo build --$BUILD_PROFILE -p installer
echo "✅ Installer built successfully"

# Check build artifacts
echo ""
echo "🔍 Checking build artifacts..."
echo "============================="

TARGET_DIR="target/$BUILD_PROFILE"
MAIN_BINARY="$TARGET_DIR/rayhunter-daemon"

if [ -f "$MAIN_BINARY" ]; then
    echo "✅ Main binary: $MAIN_BINARY ($(ls -lh "$MAIN_BINARY" | awk '{print $5}'))"
else
    echo "❌ Main binary not found: $MAIN_BINARY"
    echo "🔍 Available files in target directory:"
    ls -la "$TARGET_DIR" 2>/dev/null || echo "Target directory not found"
    exit 1
fi

# Check for web assets
if [ -d "bin/web/build" ]; then
    echo "✅ Web assets: bin/web/build ($(du -sh bin/web/build | cut -f1))"
fi

echo ""
echo "🎉 Build completed successfully!"
echo "================================"
echo ""
echo "📁 Binaries location: target/$BUILD_PROFILE/"
echo "📁 Web files location: bin/web/build/"
echo ""
echo "💡 Note: This build is for the host architecture, not ARM."
echo "   For ARM deployment, run: ./setup_arm_toolchain.sh && ./build_and_deploy.sh"
echo ""
echo "🚀 To run locally: ./target/$BUILD_PROFILE/rayhunter-daemon" 
#!/bin/bash -e

# Rayhunter Enhanced Build and Deploy Script
# Step 3: Build the app and install via adb over USB

echo "🔨 Building and deploying rayhunter-enhanced..."
echo "==============================================="

# Configuration
SOURCE_DIR="$HOME/rayhunter-enhanced"
BUILD_PROFILE="${BUILD_PROFILE:-firmware}"
TARGET_DEVICE="${TARGET_DEVICE:-auto}"

echo "📋 Build configuration:"
echo "  Source directory: $SOURCE_DIR"
echo "  Build profile: $BUILD_PROFILE"
echo "  Target device: $TARGET_DEVICE"
echo ""

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Source directory not found: $SOURCE_DIR"
    echo "🎯 Please run ./fetch_source.sh first to download the source code"
    exit 1
fi

# Change to source directory
cd "$SOURCE_DIR"

# Load build environment
echo "🔧 Loading build environment..."
if [ -f "$HOME/.rayhunter_build_env" ]; then
    source "$HOME/.rayhunter_build_env"
    echo "✅ Build environment loaded"
else
    echo "⚠️  Build environment not found. Loading from ~/.cargo/env..."
    source ~/.cargo/env 2>/dev/null || true
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

echo "✅ Cross-compilation environment configured"

# Check for build dependencies
echo ""
echo "🔍 Checking build dependencies..."

# Check Rust
if ! command -v cargo &> /dev/null; then
    echo "❌ Cargo not found. Please run ./setup_ubuntu_ci.sh first."
    exit 1
fi
echo "✅ Rust/Cargo: $(cargo --version)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please run ./setup_ubuntu_ci.sh first."
    exit 1
fi
echo "✅ Node.js: $(node --version)"

# Check adb
if ! command -v adb &> /dev/null; then
    echo "❌ adb not found. Please run ./setup_ubuntu_ci.sh first."
    exit 1
fi
echo "✅ adb: $(adb --version | head -n1)"

# Build the project
echo ""
echo "🔨 Building rayhunter-enhanced..."
echo "================================"

# Clean previous builds if requested
if [ "${CLEAN_BUILD:-false}" = "true" ]; then
    echo "🧹 Cleaning previous builds..."
    if [ -f "./clean.sh" ]; then
        ./clean.sh
    else
        cargo clean
        [ -d "bin/web/node_modules" ] && rm -rf bin/web/node_modules
        [ -d "bin/web/build" ] && rm -rf bin/web/build
    fi
    echo "✅ Clean completed"
fi

# Use the project's build script if available
if [ -f "./build_all.sh" ]; then
    echo "🔨 Using project build script..."
    # Set the build profile
    export BUILD_PROFILE="$BUILD_PROFILE"
    ./build_all.sh
else
    echo "🔨 Using manual build process..."
    
    # Build Rust components
    echo "📦 Building Rust components..."
    cargo build --profile "$BUILD_PROFILE" --target armv7-unknown-linux-musleabihf
    
    # Build web interface
    if [ -d "bin/web" ]; then
        echo "🌐 Building web interface..."
        cd bin/web
        npm install
        npm run build
        cd ../..
    fi
    
    echo "✅ Manual build completed"
fi

# Check build artifacts
echo ""
echo "🔍 Checking build artifacts..."
echo "============================="

TARGET_DIR="target/armv7-unknown-linux-musleabihf/$BUILD_PROFILE"
MAIN_BINARY="$TARGET_DIR/rayhunter-daemon"

if [ -f "$MAIN_BINARY" ]; then
    echo "✅ Main binary: $MAIN_BINARY ($(ls -lh "$MAIN_BINARY" | awk '{print $5}'))"
else
    echo "❌ Main binary not found: $MAIN_BINARY"
    echo "🔍 Available files in target directory:"
    ls -la "$TARGET_DIR" 2>/dev/null || echo "Target directory not found"
    echo ""
    echo "🔍 Looking for alternative binaries..."
    for binary in rayhunter-daemon rayhunter-check rootshell installer; do
        if [ -f "$TARGET_DIR/$binary" ]; then
            echo "✅ Found: $TARGET_DIR/$binary"
            MAIN_BINARY="$TARGET_DIR/$binary"
            break
        fi
    done
    
    if [ ! -f "$MAIN_BINARY" ]; then
        echo "❌ No rayhunter binaries found in target directory"
        exit 1
    fi
fi

# Check for web assets
if [ -d "bin/web/build" ]; then
    echo "✅ Web assets: bin/web/build ($(du -sh bin/web/build | cut -f1))"
fi

# Deploy via adb
echo ""
echo "📱 Deploying to device via adb..."
echo "================================="

# Check for connected devices
echo "🔍 Checking for connected devices..."
ADB_DEVICES=$(adb devices | grep -v "List of devices" | grep -v "^$" | wc -l)

if [ "$ADB_DEVICES" -eq 0 ]; then
    echo "❌ No devices connected via adb"
    echo "🎯 Please:"
    echo "  1. Connect your device via USB"
    echo "  2. Enable USB debugging"
    echo "  3. Authorize the connection"
    echo ""
    echo "📋 Connected devices:"
    adb devices
    exit 1
fi

echo "✅ Found $ADB_DEVICES device(s) connected"
adb devices

# Deploy the application
echo ""
echo "🚀 Deploying application..."

# Create target directory on device
DEVICE_DIR="/data/rayhunter"
echo "📁 Creating device directory: $DEVICE_DIR"
adb shell "su -c 'mkdir -p $DEVICE_DIR'"

# Push main binary
echo "📦 Pushing main binary..."
BINARY_NAME=$(basename "$MAIN_BINARY")
adb push "$MAIN_BINARY" "$DEVICE_DIR/"
adb shell "su -c 'chmod +x $DEVICE_DIR/$BINARY_NAME'"

# Push web assets if they exist
if [ -d "bin/web/build" ]; then
    echo "🌐 Pushing web assets..."
    adb shell "su -c 'mkdir -p $DEVICE_DIR/web'"
    adb push bin/web/build/* "$DEVICE_DIR/web/"
fi

# Push configuration files if they exist
if [ -f "rayhunter.conf" ]; then
    echo "⚙️  Pushing configuration..."
    adb push rayhunter.conf "$DEVICE_DIR/"
fi

# Verify deployment
echo ""
echo "✅ Deployment completed!"
echo "======================="

echo "📋 Deployed files:"
adb shell "su -c 'ls -la $DEVICE_DIR'"

echo ""
echo "🎯 To start the application on device:"
echo "  adb shell"
echo "  su"
echo "  cd $DEVICE_DIR"
echo "  ./$BINARY_NAME"
echo ""

echo "🌐 Web interface will be available at:"
echo "  http://device-ip:8080"
echo ""

echo "✅ Build and deployment completed successfully!"
echo "==============================================" 
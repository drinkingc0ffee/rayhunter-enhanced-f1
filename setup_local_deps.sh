#!/bin/bash -e

# Local Build Dependencies Setup Script for rayhunter-enhanced
# This script installs all dependencies locally in ./build_deps without requiring root access
# If basic tools (curl, tar, unzip, etc.) are missing, it will install them via apt if running as root
# Otherwise, it will provide instructions on what tools need to be installed manually

# Check for and install basic tools if running in minimal container
echo "🔍 Checking for basic tools..."
MISSING_TOOLS=()

# Check for required tools
if ! command -v curl &> /dev/null; then
    MISSING_TOOLS+=("curl")
fi

if ! command -v tar &> /dev/null; then
    MISSING_TOOLS+=("tar")
fi

if ! command -v unzip &> /dev/null; then
    MISSING_TOOLS+=("unzip")
fi

if ! command -v xz &> /dev/null; then
    MISSING_TOOLS+=("xz-utils")
fi

if ! command -v ca-certificates &> /dev/null || [ ! -d "/etc/ssl/certs" ]; then
    MISSING_TOOLS+=("ca-certificates")
fi

# Install missing tools if any
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "📦 Missing basic tools: ${MISSING_TOOLS[*]}"
    
    # Check if we're running as root and have apt available
    if [ "$EUID" -eq 0 ] && command -v apt &> /dev/null; then
        echo "🔑 Running as root - installing missing tools..."
        # Update package list
        apt update
        
        # Install missing tools
        apt install -y "${MISSING_TOOLS[@]}"
        echo "✅ Basic tools installed"
    else
        echo ""
        echo "❌ Cannot install missing tools automatically"
        echo "ℹ️  Please install these tools first:"
        echo ""
        if command -v apt &> /dev/null; then
            echo "   sudo apt update"
            echo "   sudo apt install -y ${MISSING_TOOLS[*]}"
        else
            echo "   Install: ${MISSING_TOOLS[*]}"
        fi
        echo ""
        echo "   Then run this script again"
        exit 1
    fi
else
    echo "✅ All basic tools are available"
fi

DEPS_DIR="$(pwd)/build_deps"
RUST_DIR="$DEPS_DIR/rust"
NODE_DIR="$DEPS_DIR/node"
ARM_DIR="$DEPS_DIR/arm-toolchain"
ADB_DIR="$DEPS_DIR/adb"

echo "🔧 Setting up local build dependencies for rayhunter-enhanced..."
echo "=================================================================="
echo "📁 Installation directory: $DEPS_DIR"
echo ""

# Create directories
mkdir -p "$DEPS_DIR"
mkdir -p "$RUST_DIR"
mkdir -p "$NODE_DIR"
mkdir -p "$ARM_DIR"
mkdir -p "$ADB_DIR"

# Function to download and extract
download_and_extract() {
    local url=$1
    local output=$2
    local extract_dir=$3
    
    echo "📥 Downloading $url..."
    curl -L -o "$output" "$url"
    
    if [[ "$output" == *.tar.gz ]] || [[ "$output" == *.tgz ]]; then
        tar -xzf "$output" -C "$extract_dir" --strip-components=1
    elif [[ "$output" == *.tar.xz ]]; then
        tar -xJf "$output" -C "$extract_dir" --strip-components=1
    elif [[ "$output" == *.zip ]]; then
        unzip -q "$output" -d "$extract_dir"
    fi
    
    rm "$output"
}

# Install Rust
echo "🦀 Installing Rust locally..."
if [ ! -f "$RUST_DIR/bin/rustc" ]; then
    export RUSTUP_HOME="$RUST_DIR"
    export CARGO_HOME="$RUST_DIR"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    
    # Add ARM targets
    export PATH="$RUST_DIR/bin:$PATH"
    "$RUST_DIR/bin/rustup" target add armv7-unknown-linux-musleabihf
    "$RUST_DIR/bin/rustup" target add armv7-unknown-linux-gnueabihf
    "$RUST_DIR/bin/rustup" component add rustfmt clippy
    
    echo "✅ Rust installed locally"
else
    echo "ℹ️  Rust already installed locally"
fi

# Install Node.js
echo "📦 Installing Node.js locally..."
if [ ! -f "$NODE_DIR/bin/node" ]; then
    NODE_VERSION="20.11.0"
    ARCH="linux-x64"
    NODE_URL="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-$ARCH.tar.xz"
    
    download_and_extract "$NODE_URL" "$DEPS_DIR/node.tar.xz" "$NODE_DIR"
    echo "✅ Node.js $NODE_VERSION installed locally"
else
    echo "ℹ️  Node.js already installed locally"
fi

# Install ARM cross-compilation toolchain
echo "🔧 Installing ARM cross-compilation toolchain..."
if [ ! -f "$ARM_DIR/bin/arm-linux-gnueabihf-gcc" ]; then
    # Download ARM toolchain from ARM Developer website
    ARM_VERSION="11.3.rel1"
    ARM_URL="https://developer.arm.com/-/media/Files/downloads/gnu/11.3.rel1/binrel/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz"
    
    download_and_extract "$ARM_URL" "$DEPS_DIR/arm-toolchain.tar.xz" "$ARM_DIR"
    echo "✅ ARM cross-compilation toolchain installed locally"
else
    echo "ℹ️  ARM toolchain already installed locally"
fi

# Install Android Debug Bridge (adb)
echo "📱 Installing Android Debug Bridge (adb)..."
if [ ! -f "$ADB_DIR/adb" ]; then
    ADB_VERSION="34.0.4"
    ADB_URL="https://dl.google.com/android/repository/platform-tools_r$ADB_VERSION-linux.zip"
    
    download_and_extract "$ADB_URL" "$DEPS_DIR/platform-tools.zip" "$ADB_DIR"
    # Move files from platform-tools subdirectory if it exists
    if [ -d "$ADB_DIR/platform-tools" ]; then
        mv "$ADB_DIR/platform-tools"/* "$ADB_DIR/"
        rmdir "$ADB_DIR/platform-tools"
    fi
    
    chmod +x "$ADB_DIR/adb"
    echo "✅ Android Debug Bridge installed locally"
else
    echo "ℹ️  ADB already installed locally"
fi

# Create environment setup script
echo "📝 Creating environment setup script..."
cat > "$DEPS_DIR/setup-env.sh" << EOF
#!/bin/bash

# Local build dependencies environment setup
export DEPS_DIR="$DEPS_DIR"

# Rust environment
export RUSTUP_HOME="$RUST_DIR"
export CARGO_HOME="$RUST_DIR"
export PATH="$RUST_DIR/bin:\$PATH"

# Node.js environment
export PATH="$NODE_DIR/bin:\$PATH"

# ARM cross-compilation environment
export PATH="$ARM_DIR/bin:\$PATH"
export CC_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc

export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc

# Android Debug Bridge
export PATH="$ADB_DIR:\$PATH"

echo "✅ Local build environment activated"
echo "📁 Dependencies: \$DEPS_DIR"
EOF

chmod +x "$DEPS_DIR/setup-env.sh"

# Create convenience script
echo "📝 Creating convenience script..."
cat > "use-local-deps.sh" << EOF
#!/bin/bash

# Convenience script to source local dependencies
if [ -f "./build_deps/setup-env.sh" ]; then
    source "./build_deps/setup-env.sh"
else
    echo "❌ Local dependencies not found. Run ./setup_local_deps.sh first."
    exit 1
fi
EOF

chmod +x "use-local-deps.sh"

# Verify installations
echo "🔍 Verifying local installations..."
source "$DEPS_DIR/setup-env.sh"

echo ""
echo "Tool Versions:"
echo "=============="
echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "ARM GCC: $(arm-linux-gnueabihf-gcc --version | head -n1)"
echo "adb: $(adb --version | head -n1)"

echo ""
echo "ARM Targets:"
echo "============"
rustup target list --installed | grep armv7

echo ""
echo "✅ Local build dependencies setup completed successfully!"
echo "=========================================================="
echo ""
echo "🎯 To use the local dependencies:"
echo "1. Source the environment: source ./build_deps/setup-env.sh"
echo "2. Or use convenience script: source ./use-local-deps.sh"
echo "3. Then run your build commands normally"
echo ""
echo "📁 Total size: $(du -sh $DEPS_DIR | cut -f1)"
echo "📦 Dependencies installed in: $DEPS_DIR"
echo ""
echo "🚀 Ready to build rayhunter-enhanced without root access!" 
#!/bin/bash

# Test script to verify cross-compilation environment
# This verifies that build scripts compile for host while targets compile for ARM

echo "🧪 Testing cross-compilation environment..."
echo "=========================================="

# Source build environment
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
    echo "❌ No build environment found!"
    exit 1
fi

# Apply the same fixes as build_all.sh
export PATH=$(echo "$PATH" | sed 's|/usr/arm-linux-gnueabihf/bin:||g')
export PATH="/usr/bin:/bin:$PATH"

# Unset global compiler variables
unset CC CXX AR LD CFLAGS CXXFLAGS LDFLAGS LINK
unset CARGO_TARGET_CC CARGO_TARGET_CXX CARGO_TARGET_AR CARGO_TARGET_LINKER

# Set target-specific variables
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CC=arm-linux-gnueabihf-gcc
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_CXX=arm-linux-gnueabihf-g++
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_AR=arm-linux-gnueabihf-ar

# Set host compiler variables
export CC_x86_64_unknown_linux_gnu=gcc
export CXX_x86_64_unknown_linux_gnu=g++
export AR_x86_64_unknown_linux_gnu=ar
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=gcc

echo ""
echo "🔍 Environment verification:"
echo "============================"

# Test that gcc resolves to host compiler
echo "Host compiler: $(which gcc)"
echo "Host compiler version: $(gcc --version | head -n1)"

# Test that ARM compiler is available
echo "ARM compiler: $(which arm-linux-gnueabihf-gcc)"
echo "ARM compiler version: $(arm-linux-gnueabihf-gcc --version | head -n1)"

# Test that 'cc' resolves to host compiler
if command -v cc &> /dev/null; then
    echo "cc command: $(which cc)"
    if cc --version 2>&1 | grep -q "arm-linux-gnueabihf"; then
        echo "❌ ERROR: 'cc' is ARM compiler instead of host compiler"
        exit 1
    else
        echo "✅ 'cc' is host compiler"
    fi
else
    echo "cc command: not found (will use gcc)"
fi

echo ""
echo "🧪 Testing build script compilation..."
echo "======================================"

# Create a simple test that would fail with ARM compiler
cat > /tmp/test_build_script.rs << 'EOF'
fn main() {
    println!("Build script compiled successfully for host architecture");
}
EOF

# Test that build script compiles for host
if rustc /tmp/test_build_script.rs -o /tmp/test_build_script 2>/dev/null; then
    echo "✅ Build script compilation test passed"
    /tmp/test_build_script
    rm -f /tmp/test_build_script /tmp/test_build_script.rs
else
    echo "❌ Build script compilation test failed"
    exit 1
fi

echo ""
echo "🧪 Testing simple cross-compilation..."
echo "======================================"

# Test a simple cross-compilation
if cargo check --target armv7-unknown-linux-musleabihf -p rayhunter --quiet 2>/dev/null; then
    echo "✅ ARM cross-compilation test passed"
else
    echo "❌ ARM cross-compilation test failed"
    exit 1
fi

echo ""
echo "✅ All tests passed!"
echo "==================="
echo "✅ Cross-compilation environment is working correctly"
echo "✅ Build scripts will compile for host (x86_64)"
echo "✅ Target binaries will compile for ARM" 
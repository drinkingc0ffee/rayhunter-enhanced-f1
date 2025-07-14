#!/bin/bash

# Clean build script for rayhunter-enhanced
# Removes all build artifacts for a fresh start

echo "🧹 Cleaning rayhunter-enhanced build artifacts..."
echo "================================================"

# Source build environment if available
if [ -f "./build_deps/setup-env.sh" ]; then
    source "./build_deps/setup-env.sh"
elif [ -f ~/.cargo/env ]; then
    source ~/.cargo/env
elif [ -f ~/.rayhunter_build_env ]; then
    source ~/.rayhunter_build_env
fi

# CRITICAL: Clean environment to avoid cross-compilation conflicts
# Remove any ARM cross-compiler paths from the beginning of PATH
export PATH=$(echo "$PATH" | sed 's|/usr/arm-linux-gnueabihf/bin:||g')

# Ensure system binaries come first
export PATH="/usr/bin:/bin:$PATH"

# CRITICAL: Unset all global compiler variables
unset CC CXX AR LD CFLAGS CXXFLAGS LDFLAGS LINK
unset CARGO_TARGET_CC CARGO_TARGET_CXX CARGO_TARGET_AR CARGO_TARGET_LINKER

# Clean Cargo build artifacts
echo "🗑️  Cleaning Cargo build artifacts..."
if command -v cargo &> /dev/null; then
    cargo clean
    echo "✅ Cargo artifacts cleaned"
else
    echo "⚠️  Cargo not found, skipping Cargo clean"
fi

# Clean web build artifacts
echo "🗑️  Cleaning web build artifacts..."
if [ -d "bin/web/node_modules" ]; then
    rm -rf bin/web/node_modules
    echo "✅ node_modules removed"
fi

if [ -d "bin/web/build" ]; then
    rm -rf bin/web/build
    echo "✅ web build directory removed"
fi

if [ -d "bin/web/.svelte-kit" ]; then
    rm -rf bin/web/.svelte-kit
    echo "✅ .svelte-kit directory removed"
fi

# Clean npm cache
echo "🗑️  Cleaning npm cache..."
if command -v npm &> /dev/null; then
    npm cache clean --force 2>/dev/null
    echo "✅ npm cache cleaned"
else
    echo "⚠️  npm not found, skipping npm cache clean"
fi

# Clean temporary files
echo "🗑️  Cleaning temporary files..."
find . -name "*.tmp" -delete 2>/dev/null
find . -name "*.log" -delete 2>/dev/null
find . -name ".DS_Store" -delete 2>/dev/null
echo "✅ Temporary files cleaned"

echo ""
echo "✅ Clean complete! All build artifacts removed."
echo "🔨 Run ./build_all.sh to rebuild from scratch." 
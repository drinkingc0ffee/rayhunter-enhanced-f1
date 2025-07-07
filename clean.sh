#!/bin/bash -e

# Clean script for rayhunter-enhanced
# This script removes all build artifacts for a fresh start

echo "🧹 Cleaning rayhunter-enhanced build artifacts..."
echo "==================================================\n"

# Clean Cargo build artifacts
echo "🗑️  Cleaning Cargo build artifacts..."
cargo clean
echo "✅ Cargo artifacts cleaned\n"

# Clean web build artifacts
echo "🗑️  Cleaning web build artifacts..."
if [ -d "bin/web/build" ]; then
    rm -rf bin/web/build
    echo "✅ Web build artifacts cleaned"
else
    echo "ℹ️  No web build artifacts found"
fi

if [ -d "bin/web/node_modules" ]; then
    rm -rf bin/web/node_modules
    echo "✅ Node modules cleaned"
else
    echo "ℹ️  No node modules found"
fi

if [ -f "bin/web/package-lock.json" ]; then
    rm -f bin/web/package-lock.json
    echo "✅ Package lock removed"
else
    echo "ℹ️  No package lock found"
fi

echo ""
echo "🎉 All build artifacts cleaned successfully!"
echo "🚀 Run ./build_all.sh to rebuild everything" 
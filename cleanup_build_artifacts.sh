#!/bin/bash

# Cleanup Build Artifacts Script for rayhunter-enhanced
# This script removes build artifacts and temporary files to save space

echo "🧹 Cleaning up build artifacts and temporary files..."
echo "===================================================="

# Clean Rust build artifacts
if [ -d "target" ]; then
    echo "🗑️  Cleaning Rust target directory..."
    rm -rf target/
    echo "✅ Rust artifacts cleaned"
fi

# Clean Node.js artifacts
if [ -d "bin/web/node_modules" ]; then
    echo "🗑️  Cleaning Node.js modules..."
    rm -rf bin/web/node_modules/
    echo "✅ Node.js modules cleaned"
fi

if [ -d "bin/web/build" ]; then
    echo "🗑️  Cleaning web build artifacts..."
    rm -rf bin/web/build/
    echo "✅ Web build artifacts cleaned"
fi

# Clean build_deps if it exists and is not empty
if [ -d "build_deps" ] && [ "$(ls -A build_deps)" ]; then
    echo "🗑️  Cleaning local build dependencies..."
    rm -rf build_deps/
    echo "✅ Local build dependencies cleaned"
fi

# Clean any backup files
if ls *.backup 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning backup files..."
    rm -f *.backup
    echo "✅ Backup files cleaned"
fi

# Clean any temporary files
if ls *.tmp 1> /dev/null 2>&1; then
    echo "🗑️  Cleaning temporary files..."
    rm -f *.tmp
    echo "✅ Temporary files cleaned"
fi

echo ""
echo "🎉 Cleanup completed!"
echo "====================="
echo "📊 Disk space freed:"
du -sh . 2>/dev/null || echo "Current directory size: $(du -sh . | cut -f1)"
echo ""
echo "🚀 To rebuild the project, run:"
echo "  ./build_all.sh" 
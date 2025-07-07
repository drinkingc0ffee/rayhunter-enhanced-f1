#!/bin/bash -e

# Comprehensive build script for rayhunter-enhanced
# This script builds all components in the correct order

echo "🏗️  Building rayhunter-enhanced..."
echo "=====================================\n"

# Build web frontend first
echo "📦 Building web frontend..."
cd bin/web
npm install
npm run build
cd ../..
echo "✅ Web frontend built successfully\n"

# Build library and core binaries first
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
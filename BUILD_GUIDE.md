# 🏗️ Build Guide - Rayhunter Enhanced

This guide covers how to build and deploy the rayhunter-enhanced project.

## 🚀 Quick Start

For a complete clean build and deploy:

```bash
# Clean previous builds
./clean.sh

# Build everything
./build_all.sh

# Deploy to device
./deploy.sh
```

## 📋 Prerequisites

### System Requirements
- **Rust** (latest stable version)
- **Node.js** and **npm**
- **adb** (Android Debug Bridge) for device deployment
- **ARM cross-compilation toolchain**

### Install ARM Target
```bash
rustup target add armv7-unknown-linux-musleabihf
```

## 🛠️ Build Scripts

### `./build_all.sh`
Comprehensive build script that:
- Builds web frontend (SvelteKit)
- Builds Rust library
- Builds all ARM firmware binaries
- Handles dependencies in correct order

### `./deploy.sh`
Deployment script that:
- Checks device connection
- Stops existing daemon
- Deploys binaries and web interface
- Reboots device
- Starts daemon service

### `./clean.sh`
Cleanup script that:
- Removes all Cargo build artifacts
- Removes web build artifacts
- Removes node_modules
- Prepares for fresh build

## 🔧 Manual Build Process

If you need to build components individually:

### 1. Web Frontend
```bash
cd bin/web
npm install
npm run build
cd ../..
```

### 2. Rust Library
```bash
cargo build --release --target armv7-unknown-linux-musleabihf -p rayhunter
```

### 3. Firmware Binaries
```bash
# Build rootshell first (required by installer)
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p rootshell

# Build daemon
cargo build --profile firmware --target armv7-unknown-linux-musleabihf --bin rayhunter-daemon

# Build utilities
cargo build --profile firmware --target armv7-unknown-linux-musleabihf --bin rayhunter-check

# Build installer (depends on firmware binaries)
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p installer
```

## 📁 Build Output Locations

- **ARM Binaries**: `target/armv7-unknown-linux-musleabihf/firmware/`
- **Web Interface**: `bin/web/build/`

## 🎯 Build Profiles

- **release**: Standard release build with debug info
- **firmware**: Optimized for embedded devices (smaller size, no debug info)

## 🔧 Legacy Build Scripts

- **`make.sh`**: Original build and deploy script (updated)
- **`docker_make.sh`**: Docker-based build script (updated)

## 🐛 Troubleshooting

### Dependency Issues
The installer depends on firmware binaries being built first. If you see errors about missing firmware binaries:

```bash
# Build dependencies first
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p rootshell

# Then build installer
cargo build --profile firmware --target armv7-unknown-linux-musleabihf -p installer
```

### Clean Build
If you encounter persistent build issues:

```bash
./clean.sh
./build_all.sh
```

### Device Connection
Ensure your device is connected and accessible:

```bash
adb devices
# Should show your device as "device"
```

## 📝 Notes

- **lib/Cargo.toml**: Updated with correct tokio and chrono features
- **Build Order**: Web → Library → Firmware → Installer
- **Target**: armv7-unknown-linux-musleabihf (ARM hard float)
- **Profiles**: Use `firmware` profile for device binaries

## 🔄 CI/CD

The GitHub Actions workflows are configured correctly and will:
- Build web interface
- Build firmware binaries
- Run tests
- Create release packages

For local development, use the scripts in this guide. 
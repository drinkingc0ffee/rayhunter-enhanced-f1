# Ubuntu Setup Guide for Rayhunter Enhanced

This guide covers setting up the build environment for rayhunter-enhanced on Ubuntu systems.

## Prerequisites

**IMPORTANT: Always start with updating your package lists:**

```bash
sudo apt update
```

This ensures you have the latest package information and prevents dependency issues.

## Setup Options

### Option 1: Local Dependencies (Recommended)
No root access needed after initial tool installation. Downloads and installs all dependencies locally.

```bash
# Install basic tools if missing (one-time setup)
sudo apt update
sudo apt install -y curl tar unzip xz-utils ca-certificates

# Install dependencies locally
./setup_local_deps.sh

# Build the project
./build_all.sh
```

### Option 2: System-Wide CI Setup
Installs everything system-wide. Good for CI/CD environments.

```bash
# This script runs apt update automatically at the beginning
./setup_ubuntu_ci.sh
./fetch_source.sh
./build_and_deploy.sh
```

### Option 3: Interactive Setup
Full interactive setup with options for Docker, additional tools, etc.

```bash
# This script runs apt update automatically at the beginning
./setup_ubuntu_build_env.sh
./build_all.sh
```

## Docker Setup

For containerized builds:

```bash
# Build Docker environment
./docker-build.sh

# Run container
docker-compose up -d

# Access the container
docker exec -it rayhunter-build-env bash
```

## Environment Verification

Before building, verify your environment:

```bash
./test_build.sh
```

This will check:
- Build environment setup
- Required tools (Rust, Node.js, ARM cross-compiler)
- Rust targets
- Cross-compilation capability
- Web build dependencies

## Common Issues

### Package Cache Issues
If you see warnings about old package cache, run:
```bash
sudo apt update
```

### Missing Tools
If basic tools are missing, install them:
```bash
sudo apt update
sudo apt install -y build-essential curl git
```

### ARM Cross-Compiler Issues
If ARM cross-compilation fails:
```bash
sudo apt update
sudo apt install -y gcc-arm-linux-gnueabihf libc6-dev-armhf-cross
```

## Build Commands

Once environment is set up:

```bash
# Clean build
./clean.sh

# Full build
./build_all.sh

# Test build environment
./test_build.sh

# Deploy to device
./deploy.sh
```

## Environment Variables

The setup scripts configure these automatically:
- `CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc`
- `CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc`
- Proper PATH for all tools

## Troubleshooting

### Build Errors
1. Run `./test_build.sh` to diagnose issues
2. Check that `apt update` was run recently
3. Verify all tools are installed: `rustc --version`, `node --version`, `arm-linux-gnueabihf-gcc --version`

### Permission Errors
- Don't run setup scripts as root (except for system package installation)
- Ensure user has sudo privileges

### Cross-Compilation Errors
- Verify ARM toolchain: `arm-linux-gnueabihf-gcc --version`
- Check Rust targets: `rustup target list --installed | grep armv7`

## Support

For issues:

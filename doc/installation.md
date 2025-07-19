# Installing Rayhunter Enhanced

So, you've got one of the [supported devices](./supported-devices.md), and are ready to start catching IMSI catchers. You have several options for installing Rayhunter Enhanced:

## 🚀 Quick Start Options

### Option 1: Docker Environment (Recommended for New Users)
The Docker environment provides a complete, isolated build environment with all dependencies pre-configured:

```bash
# Clone the repository
git clone https://github.com/your-repo/rayhunter-enhanced.git
cd rayhunter-enhanced

# Start Docker environment
./docker-build.sh up
./docker-build.sh shell

# Inside container - simple 3-step process
./setup_ubuntu_ci.sh     # Install toolchains & dependencies
./fetch_source.sh        # Download latest source code (if needed)
./build_and_deploy.sh    # Build and deploy to device
```

**Docker Benefits:**
- ✅ **Isolated environment** - No system modifications required
- ✅ **All dependencies included** - Ubuntu 22.04 with full toolchain
- ✅ **Persistent storage** - Work survives container restarts
- ✅ **Cross-compilation ready** - ARM toolchain pre-configured
- ✅ **adb support** - Direct device deployment via USB

### Option 2: Ubuntu Automated Setup
For Ubuntu systems, use the automated setup scripts:

```bash
# Clone the repository
git clone https://github.com/your-repo/rayhunter-enhanced.git
cd rayhunter-enhanced

# Set up build environment (one-time setup)
./setup_ubuntu_ci.sh     # Automated setup for CI/CD

# Build everything and deploy
./build_all.sh && ./deploy.sh
```

### Option 3: Local Dependencies (No Root Required)
Install all dependencies locally without affecting your system:

```bash
# Clone the repository
git clone https://github.com/your-repo/rayhunter-enhanced.git
cd rayhunter-enhanced

# Install all dependencies locally (no root access needed)
./setup_local_deps.sh

# Build everything and deploy
./build_all.sh && ./deploy.sh
```

## 📋 Traditional Installation Options

* [installing from a release (recommended)](./installing-from-release.md)
  * [installing from a release on Windows](./installing-from-release-windows.md)
* [installing from source](./installing-from-source.md)

## 🔧 Enhanced Features

Rayhunter Enhanced includes several improvements over the original:

- **GPS Integration**: Real-time GPS coordinate submission via REST API
- **Enhanced Build System**: Cross-compilation fixes and multiple setup options
- **Docker Support**: Complete isolated build environment
- **Mobile App Compatibility**: GPS2REST-Android integration
- **Multiple Export Formats**: CSV, JSON, GPX for GPS data
- **Advanced Cellular Analysis**: 3x more log codes and neighbor cell tracking

## 📚 Documentation

For comprehensive setup instructions, see:
- **[BUILD_GUIDE.md](../BUILD_GUIDE.md)** - Complete build guide with cross-compilation fixes
- **[docker-build/DOCKER_BUILD_GUIDE.md](../docker-build/DOCKER_BUILD_GUIDE.md)** - Docker environment guide
- **[README_ENHANCED.md](../README_ENHANCED.md)** - Project overview and features
- **[DOCUMENTATION_INDEX.md](../DOCUMENTATION_INDEX.md)** - Complete documentation index

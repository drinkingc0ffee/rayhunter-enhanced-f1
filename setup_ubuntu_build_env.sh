#!/bin/bash -e

# Ubuntu Build Environment Setup Script for rayhunter-enhanced
# This script installs all necessary dependencies for building the project

echo "🔧 Setting up Ubuntu build environment for rayhunter-enhanced..."
echo "================================================================\n"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    print_error "sudo is required but not installed. Please install sudo first."
    exit 1
fi

print_info "Starting Ubuntu build environment setup..."

if [ "$IS_ROOT" = true ]; then
    print_warning "Running as root - additional considerations:"
    echo "  • Rust will be installed system-wide in /opt/rust"
    echo "  • All tools will be installed system-wide"
    echo "  • No user group changes will be made"
    echo "  • Configuration files will be in /root/"
    echo ""
fi

# Update package lists
print_info "Updating package lists..."
sudo apt update
print_status "Package lists updated"

# Install basic build dependencies
print_info "Installing basic build dependencies..."
sudo apt install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release
print_status "Basic build dependencies installed"

# Install ARM cross-compilation tools
print_info "Installing ARM cross-compilation tools..."
sudo apt install -y \
    libc6-armhf-cross \
    libc6-dev-armhf-cross \
    gcc-arm-linux-gnueabihf \
    g++-arm-linux-gnueabihf
print_status "ARM cross-compilation tools installed"

# Install Rust if not already installed
if ! command -v rustc &> /dev/null; then
    print_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
    print_status "Rust installed"
else
    print_info "Rust is already installed"
    # Update Rust to latest stable
    source ~/.cargo/env
    rustup update stable
    print_status "Rust updated to latest stable"
fi

# Ensure we have the latest Rust components
print_info "Installing/updating Rust components..."
source ~/.cargo/env
rustup component add rustfmt clippy
print_status "Rust components installed"

# Install ARM target for Rust
print_info "Installing ARM target for Rust..."
rustup target add armv7-unknown-linux-musleabihf
rustup target add armv7-unknown-linux-gnueabihf
print_status "ARM targets installed"

# Install Node.js and npm
if ! command -v node &> /dev/null; then
    print_info "Installing Node.js and npm..."
    # Install Node.js via NodeSource repository for latest LTS
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    print_status "Node.js and npm installed"
else
    print_info "Node.js is already installed"
    node --version
    npm --version
fi

# Install Android Debug Bridge (adb)
print_info "Installing Android Debug Bridge (adb)..."
sudo apt install -y android-tools-adb android-tools-fastboot
print_status "adb installed"

# Install Docker (optional, for docker_make.sh)
read -p "Do you want to install Docker for containerized builds? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing Docker..."
    
    # Remove old Docker packages
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install Docker from official repository
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    print_warning "You need to log out and log back in for Docker group changes to take effect"
    print_status "Docker installed"
else
    print_info "Skipping Docker installation"
fi

# Install additional useful tools
print_info "Installing additional development tools..."
sudo apt install -y \
    htop \
    tree \
    jq \
    vim \
    nano \
    screen \
    tmux
print_status "Additional development tools installed"

# Create a desktop shortcut for easy access to build commands
print_info "Creating build environment info..."
INFO_FILE="~/rayhunter-build-info.txt"

cat > "$INFO_FILE" << EOF
Rayhunter Enhanced Build Environment
====================================

Build Commands:
- Clean build: ./clean.sh
- Build all: ./build_all.sh  
- Deploy: ./deploy.sh
- Quick build+deploy: ./make.sh

Development:
- Check code: cargo check
- Run tests: cargo test
- Format code: cargo fmt
- Lint code: cargo clippy

Web Development:
- Dev server: cd bin/web && npm run dev
- Build web: cd bin/web && npm run build

Device Management:
- List devices: adb devices
- Shell access: adb shell
- Root shell: adb shell '/bin/rootshell -c bash'

ARM Targets Available:
- armv7-unknown-linux-musleabihf
- armv7-unknown-linux-gnueabihf

Build Profiles:
- release: Standard release build
- firmware: Optimized for embedded devices

ARM Cross-Compilation:
- Environment variables automatically configured
- Uses arm-linux-gnueabihf-gcc toolchain
- Targets ARM hard float (armhf) architecture
EOF

print_status "Build environment info created at $INFO_FILE"

# Set up shell environment
print_info "Setting up shell environment..."

# Set up ARM cross-compilation environment variables
print_info "Setting up ARM cross-compilation environment..."
export CC_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc

export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc

PROFILE_FILE="$HOME/.bashrc"
if ! grep -q "source ~/.cargo/env" "$PROFILE_FILE" 2>/dev/null; then
    echo "source ~/.cargo/env" >> "$PROFILE_FILE"
fi

# Add ARM cross-compilation environment variables to .bashrc
if ! grep -q "CC_armv7_unknown_linux_musleabihf" "$PROFILE_FILE" 2>/dev/null; then
    cat >> "$PROFILE_FILE" << 'EOF'

# ARM cross-compilation environment variables
export CC_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_musleabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER=arm-linux-gnueabihf-gcc

export CC_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-gcc
export CXX_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-g++
export AR_armv7_unknown_linux_gnueabihf=arm-linux-gnueabihf-ar
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=arm-linux-gnueabihf-gcc
EOF
fi

# Create useful aliases
if ! grep -q "alias ll=" "$PROFILE_FILE" 2>/dev/null; then
    cat >> "$PROFILE_FILE" << 'EOF'

# Rayhunter build aliases
alias ll='ls -la'
alias rh-build='./build_all.sh'
alias rh-deploy='./deploy.sh'
alias rh-clean='./clean.sh'
alias rh-devices='adb devices'
alias rh-shell='adb shell "/bin/rootshell -c bash"'
EOF
fi

print_status "Shell environment configured"

# Verify installations
print_info "Verifying installations..."
echo "System Information:"
echo "===================="
echo "OS: $(lsb_release -d | cut -f2)"
echo "Architecture: $(dpkg --print-architecture)"
echo ""

echo "Tool Versions:"
echo "=============="
echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "gcc: $(gcc --version | head -n1)"
echo "ARM GCC: $(arm-linux-gnueabihf-gcc --version | head -n1)"
echo "adb: $(adb --version | head -n1)"
if command -v docker &> /dev/null; then
    echo "Docker: $(docker --version)"
fi

echo ""
echo "Rust Targets:"
echo "============="
rustup target list --installed | grep armv7

echo ""
echo "ARM Cross-Compilation Environment:"
echo "=================================="
echo "CC_armv7_unknown_linux_musleabihf: $CC_armv7_unknown_linux_musleabihf"
echo "CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER: $CARGO_TARGET_ARMV7_UNKNOWN_LINUX_MUSLEABIHF_LINKER"

print_status "All installations verified"

echo ""
echo "🎉 Ubuntu build environment setup completed successfully!"
echo "=========================================================="
echo ""
print_info "Next steps:"
if command -v docker &> /dev/null; then
    echo "1. Log out and log back in (if Docker was installed)"
    echo "2. Clone the rayhunter-enhanced repository"
    echo "3. Run: source ~/.bashrc"
    echo "4. Test the build: ./build_all.sh"
else
    echo "1. Clone the rayhunter-enhanced repository"
    echo "2. Run: source ~/.bashrc"
    echo "3. Test the build: ./build_all.sh"
fi
echo ""
print_info "Helpful files created:"
echo "- $INFO_FILE - Build commands reference"
echo "- $PROFILE_FILE - Updated with Rust environment and aliases"
echo ""
print_info "Useful aliases added:"
echo "- rh-build    -> ./build_all.sh"
echo "- rh-deploy   -> ./deploy.sh"
echo "- rh-clean    -> ./clean.sh"
echo "- rh-devices  -> adb devices"
echo "- rh-shell    -> adb shell '/bin/rootshell -c bash'"
echo ""
print_warning "Remember to connect your device via USB and enable USB debugging before building!" 
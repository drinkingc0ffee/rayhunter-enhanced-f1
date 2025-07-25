#!/bin/bash -e

echo "🐳 Building test_qr for ARM using Docker..."

# Build the Docker environment
docker build -t rayhunter-devenv -f devenv.dockerfile .

echo "✅ Docker image built successfully!"

# Build the test_qr binary for ARM
echo "🔨 Building test_qr binary for ARM..."
docker run --user $UID:$GID -v ./:/workdir -w /workdir -it rayhunter-devenv sh -c 'cd daemon && cargo build --release --bin test_qr --features orbic --target="armv7-unknown-linux-gnueabihf"'

echo "✅ test_qr binary built successfully!"

# Push the binary to the device
echo "📱 Pushing test_qr to device..."
adb push daemon/target/armv7-unknown-linux-gnueabihf/release/test_qr /tmp/

# Make it executable
echo "🔧 Making test_qr executable..."
adb shell "chmod +x /tmp/test_qr"

echo "🎉 test_qr is ready! Run it with:"
echo "adb shell \"/bin/rootshell /tmp/test_qr\""

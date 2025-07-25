#!/bin/bash
# run_test_qr.sh
# This script builds and runs the test_qr binary on the connected device using adb

set -e

DEVICE_ID="48600131"
BINARY_PATH="target/debug/test_qr"
REMOTE_PATH="/data/local/tmp/test_qr"

# Build the test_qr binary for the device (assumes cross-compilation is set up)
cargo build --bin test_qr

# Push the binary to the device
adb -s "$DEVICE_ID" push "$BINARY_PATH" "$REMOTE_PATH"

# Run the test on the device
adb -s "$DEVICE_ID" shell chmod +x "$REMOTE_PATH"
adb -s "$DEVICE_ID" shell "$REMOTE_PATH"

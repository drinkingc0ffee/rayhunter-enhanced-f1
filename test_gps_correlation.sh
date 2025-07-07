#!/bin/bash

# Test script for GPS correlation functionality
# This script tests the GPS API and download endpoints

BASE_URL="http://192.168.1.1:8080"  # Replace with your device IP
RECORDING_ID="test_recording"  # Replace with actual recording ID

echo "=== Testing GPS Correlation System ==="
echo

# First, let's add some test GPS coordinates
echo "1. Adding test GPS coordinates..."

# Add a few GPS coordinates with timestamps
curl -X POST "${BASE_URL}/api/v1/gps/37.7749,-122.4194" \
  -H "Content-Type: application/json" \
  && echo " ✓ GPS point 1 added"

sleep 2

curl -X POST "${BASE_URL}/api/v1/gps/37.7849,-122.4094" \
  -H "Content-Type: application/json" \
  && echo " ✓ GPS point 2 added"

sleep 2

curl -X POST "${BASE_URL}/api/v1/gps/37.7949,-122.3994" \
  -H "Content-Type: application/json" \
  && echo " ✓ GPS point 3 added"

echo

# Check if there are any recording sessions available
echo "2. Checking available recordings..."
curl -s "${BASE_URL}/api/qmdl-manifest" | jq '.entries[0].name' | head -1

echo

# Test GPS download endpoints (these will fail if no recordings exist)
echo "3. Testing GPS download endpoints..."

# You'll need to replace RECORDING_ID with an actual recording ID from the manifest
echo "To test downloads, replace RECORDING_ID in this script with an actual recording ID from:"
echo "${BASE_URL}/api/qmdl-manifest"

echo

echo "Example download URLs:"
echo "CSV:  ${BASE_URL}/api/gps/RECORDING_ID/csv"
echo "JSON: ${BASE_URL}/api/gps/RECORDING_ID/json"
echo "GPX:  ${BASE_URL}/api/gps/RECORDING_ID/gpx"

echo

echo "=== GPS Correlation Test Complete ==="
echo "Check the web interface at ${BASE_URL} to see the new GPS download buttons!"
